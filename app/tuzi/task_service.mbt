///|
priv struct TaskService {
  session : String
  mut revision : Int32
  mut next_id : Int32
  mut tasks : Array[@shared.Task]
  slots : @async.Semaphore
  mut subscribers : Array[(Int32, @async.Queue[Unit])]
  mut next_subscriber : Int32
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
) -> Int32 {
  let id = self.next_subscriber
  self.next_subscriber += 1
  self.subscribers.push((id, queue))
  id
}

///|
fn TaskService::unsubscribe(self : TaskService, id : Int32) -> Unit {
  self.subscribers = self.subscribers.filter(pair => pair.0 != id)
}

///|
fn TaskService::broadcast(self : TaskService) -> Unit raise {
  self.subscribers.each(pair => ignore(pair.1.try_put(())))
}

///|
fn TaskService::snapshot(self : TaskService) -> @shared.TaskSnapshot {
  { session: self.session, revision: self.revision, tasks: self.tasks, }
}

///|
fn TaskService::start(self : TaskService, id : Int32) -> Unit raise {
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
  id : Int32,
  status : @shared.TaskStatus,
) -> Unit raise {
  let task = self.tasks.iter().find_first(task => task.id == id).unwrap()
  self.tasks = [{ ..task, status, }, ..self.tasks.filter(task => task.id != id)]
  self.revision += 1
  self.broadcast()
}

///|
priv struct PreparedTask {
  kind : @shared.TaskKind
  execute : async () -> String
}

///|
fn TaskService::submit(
  self : TaskService,
  requests : Array[Result[@shared.TaskKind, @shared.ApiFailure]],
  group : @async.TaskGroup[Unit],
  log : Bool,
) -> Array[@shared.ApiResponse[Int32]] raise {
  let prepared = requests.map(result => {
    result.map(kind => {
      let execute : async () -> String = match kind {
        File(operation) => {
          validate_file_operation_input(operation)
          () => {
            execute_file_operation(operation)
            ""
          }
        }
        Git(request) => {
          let arguments = @git.git_arguments(request.operation)
          () => @git.run_git(request.path, arguments)
        }
      }
      PreparedTask::{ kind, execute, }
    }) catch {
      error => Err(api_failure(error))
    }
  })
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
        write_operation_log(log, description)
      }
    })
    @shared.ApiResponse::Success(id)
  })
  if results.any(result => result is Success(_)) {
    self.broadcast()
  }
  results
}
