///|
fn routes(
  config : @shared.ServerConfig,
  log : Bool,
  tasks : TaskService,
  group : @async.TaskGroup[Unit],
  openers : OpenService,
) -> @moonback.Module {
  ctx => {
    ctx
    ..get("/api/base", (_req, res) => respond(res, () => config))
    ..get("/api/drives", (_req, res) => respond(res, () => list_drives()))
    ..get("/api/image", serve_image)
    ..get("/api/file/:name", serve_file)
    ..post("/api/open", (req, res) => {
      respond(res, () => {
        let request : @shared.OpenRequest = decode_request(req)
        log_op(log, "open: \{request.opener}: \{request.path}")
        openers.open(request)
      })
    })
    ..post("/api/list", (req, res) => {
      respond(res, () => {
        let request : @shared.ListingRequest = decode_request(req)
        log_op(log, "list: \{request.path}")
        list_entries(request.path, include_markers=request.include_markers)
      })
    })
    ..post("/api/link", (req, res) => {
      respond(res, () => {
        let request : @shared.DirectoryRequest = decode_request(req)
        read_link_target(request.path)
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
// Async stdout permits only one pending write.
let log_mutex : @async.Mutex = Mutex()

///|
async fn log_op(enabled : Bool, msg : String) -> Unit {
  guard enabled else { return }
  log_mutex.acquire()
  defer log_mutex.release()
  @stdio.stdout.write("[tuzi] \{msg}\n")
}
