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
      let arguments = @git.git_arguments(request.operation)
      () => @git.run_git(request.path, arguments)
    }
  }
  { kind, execute, }
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
