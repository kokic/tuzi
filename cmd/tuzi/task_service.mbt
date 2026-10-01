///|
/// Request validation and command construction finish before a task gets an id.
priv struct PreparedTask {
  kind : @shared.TaskKind
  execute : async () -> String
}

///|
fn prepare_task(kind : @shared.TaskKind) -> PreparedTask raise {
  let execute : async () -> String = match kind {
    File(operation) => {
      validate_file_operation_input(operation)
      () => {
        execute_file_operation(operation)
        ""
      }
    }
    Git(request) => {
      let arguments = git_arguments(request.operation)
      () => run_git(request.path, arguments)
    }
  }
  { kind, execute, }
}

///|
/// Task ownership is tied to the server scope, never an HTTP connection.
priv struct TaskService {
  session : String
  mut revision : Int
  mut next_id : Int
  /// Tasks remain available for the lifetime of this server session.
  mut tasks : Array[@shared.Task]
  slots : @async.Semaphore
  /// Each subscriber retains at most one notification to read the latest state.
  mut subscribers : Array[(Int, @async.Queue[Unit])]
  mut next_subscriber : Int
}

///|
fn TaskService::new() -> TaskService {
  {
    session: @async.now().to_string(),
    revision: 0,
    next_id: 0,
    tasks: [],
    slots: @async.Semaphore(4),
    subscribers: [],
    next_subscriber: 0,
  }
}

///|
fn TaskService::subscribe(
  self : TaskService,
  queue : @async.Queue[Unit],
) -> Int {
  let id = self.next_subscriber
  self.next_subscriber += 1
  self.subscribers.push((id, queue))
  id
}

///|
fn TaskService::unsubscribe(self : TaskService, id : Int) -> Unit {
  self.subscribers = self.subscribers.filter(pair => pair.0 != id)
}

///|
/// Coalesce changes for slow subscribers without retaining obsolete snapshots.
fn TaskService::broadcast(self : TaskService) -> Unit raise {
  self.subscribers.each(pair => ignore(pair.1.try_put(())))
}

///|
fn TaskService::snapshot(self : TaskService) -> @shared.TaskSnapshot {
  { session: self.session, revision: self.revision, tasks: self.tasks, }
}

///|
fn TaskService::submit(
  self : TaskService,
  prepared : Array[Result[PreparedTask, @shared.ApiFailure]],
  group : @async.TaskGroup[Unit],
  log : Bool,
) -> Array[@shared.ApiResponse[Int]] raise {
  let results = prepared.map(result => {
    let task = match result {
      Ok(task) => task
      Err(error) => return @shared.ApiResponse::Failure(error)
    }
    let { kind, execute, } = task
    let id = self.next_id
    self.next_id += 1
    let description = match kind {
      File(operation) => operation.description()
      Git(request) =>
        "git \{request.operation.name()} · \{request.path.dirname()}"
    }
    self.tasks = [{ id, kind, description, status: Queued, }, ..self.tasks]
    self.revision += 1
    group.spawn_bg(() => {
      let status : @shared.TaskStatus = try {
        self.slots.acquire()
        defer self.slots.release()
        self.start(id)
        Completed(execute())
      } catch {
        error => Failed(api_failure(error))
      }
      self.finish(id, status)
      if status is Completed(_) {
        log_op(log, description)
      }
    })
    @shared.ApiResponse::Success(id)
  })
  if results.any(result => result is Success(_)) {
    self.broadcast()
  }
  results
}

///|
/// Starting a task changes its status without reordering the activity history.
fn TaskService::start(self : TaskService, id : Int) -> Unit raise {
  self.tasks = self.tasks.map(task => {
    if task.id == id {
      { ..task, status: Running, }
    } else {
      task
    }
  })
  self.revision += 1
  self.broadcast()
}

///|
fn TaskService::finish(
  self : TaskService,
  id : Int,
  status : @shared.TaskStatus,
) -> Unit raise {
  let task = self.tasks.iter().find_first(task => task.id == id).unwrap()
  self.tasks = [{ ..task, status, }, ..self.tasks.filter(task => task.id != id)]
  self.revision += 1
  self.broadcast()
}
