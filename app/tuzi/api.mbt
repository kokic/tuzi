///|
fn routes(
  config : @shared.ServerConfig,
  log : Bool,
  tasks : TaskService,
  group : @async.TaskGroup[Unit],
) -> @moonback.Module {
  ctx => {
    ctx
    ..get("/api/base", (_req, res) => respond(res, () => config))
    ..get("/api/image", serve_image)
    ..get("/api/file/:name", serve_file)
    ..post("/api/list", (req, res) => {
      respond(res, () => {
        let request : @shared.ListingRequest = decode_request(req)
        log_op(log, "list: \{request.path}")
        list_entries(request.path, include_markers=request.include_markers)
      })
    })
    ..get("/api/tasks", (_req, res) => respond(res, () => tasks.snapshot()))
    ..get("/api/tasks/events", (req, res) => task_events(req, res, tasks))
    ..post("/api/tasks", (req, res) => {
      respond(res, () => {
        let entries : Array[Json] = decode_request(req)
        let prepared = entries.map(entry => {
          Ok(prepare_task(decode_json(entry))) catch {
            error => Err(api_failure(error))
          }
        })
        @shared.TaskSubmission::{
          session: tasks.session,
          results: tasks.submit(prepared, group, log),
        }
      })
    })
    .post("/api/git/info", (req, res) => {
      respond(res, () => {
        let request : @shared.DirectoryRequest = decode_request(req)
        read_git_info(request.path)
      })
    })
  }
}

///|
/// Heartbeats let clients detect broken connections. The upgraded socket
/// must remain inside this handler's lifetime.
async fn task_events(
  req : @moonback.Request,
  res : @moonback.Responder,
  tasks : TaskService,
) -> Unit {
  let conn = res.upgrade(req)
  let queue : @async.Queue[Unit] = @async.Queue::Queue(kind=@aqueue.Blocking(1))
  defer queue.close()
  let id = tasks.subscribe(queue)
  defer tasks.unsubscribe(id)
  @async.with_timeout(30_000, () => {
    conn.send_text(ToJson::to_json(tasks.snapshot()).stringify())
  })
  @async.with_task_group(root => {
    root.spawn_bg(() => {
      while true {
        ignore(conn.recv())
      }
    })
    while true {
      @async.with_timeout(15_000, () => queue.get()) catch {
        @async.TimeoutError => ()
        error => raise error
      }
      @async.with_timeout(30_000, () => {
        conn.send_text(ToJson::to_json(tasks.snapshot()).stringify())
      })
    }
  })
}

///|
priv suberror RequestError {
  InvalidRequest(String)
}

///|
fn[T : @json.FromJson] decode_json(value : Json) -> T raise RequestError {
  @json.from_json(value) catch {
    error => raise InvalidRequest(error.to_string())
  }
}

///|
async fn[T : @json.FromJson] decode_request(req : @moonback.Request) -> T {
  let text = req.body.text()
  let value = @json.parse(text) catch {
    error => raise InvalidRequest(error.to_string())
  }
  decode_json(value)
}

///|
async fn[T : ToJson] respond(
  res : @moonback.Responder,
  action : async () -> T,
) -> Unit {
  let response : @shared.ApiResponse[T] = Success(action()) catch {
    error => Failure(api_failure(error))
  }
  res.send_json(ToJson::to_json(response))
}

///|
fn api_failure(error : Error) -> @shared.ApiFailure {
  let (code, message) : (@shared.ApiErrorCode, String) = match error {
    InvalidRequest(message) => (InvalidRequest, message)
    FileError::InvalidName(name) | ArchiveError::InvalidName(name) =>
      (InvalidName, "Invalid name: " + name)
    InvalidTarget(message) | OutputIsInput(message) => (InvalidTarget, message)
    FileError::UnsupportedEntry(path) | ArchiveError::UnsupportedEntry(path) =>
      (Unsupported, "Unsupported entry: " + path)
    PartialFailure(message) => (PartialFailure, message)
    EmptySelection => (InvalidRequest, "Select at least one entry")
    GitBusy => (Busy, "A Git operation is already running for this repository")
    GitMissing => (GitUnavailable, "Install Git to enable this operation")
    CommandFailed(message) => (GitFailed, message)
    @os_error.OSError(_, ..) as error if error.is_EEXIST() =>
      (Conflict, error.to_string())
    @os_error.OSError(_, ..) as error if error.is_EACCES() =>
      (PermissionDenied, error.to_string())
    @os_error.OSError(_, ..) as error if error.is_ENOENT() =>
      (NotFound, error.to_string())
    _ => (Io, error.to_string())
  }
  { code, message, }
}

///|
// Async stdout permits only one pending write.
let log_mutex : @async.Mutex = Mutex()

///|
async fn log_op(enabled : Bool, msg : String) -> Unit {
  guard enabled else { return }
  log_mutex.acquire()
  defer log_mutex.release()
  @stdio.stdout.write("[tuzi] \{msg}\n")
}
