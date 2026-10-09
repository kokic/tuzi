///|
priv enum TaskMsg {
  TasksSubmitted(
    SubmissionContext,
    Result[@tuzi.TaskSubmission, RequestFailure]
  )
  TaskOpen(Int)
  TaskOutputOpen(Int)
  TaskSocket(Int, @websocket.Event)
  TaskSocketFailed(Int, String)
  TaskReconnect(Int)
  TaskConnectionCheck(Int)
}

///|
priv enum SubmissionContext {
  Background
  Files(FileSubmission)
  GitRename(
    dialog_revision~ : Int,
    context~ : GitContext,
    input_dialog~ : Dialog
  )
}

///|
priv struct FileSubmission {
  dialog_revision : Int
  progress : ProgressBatch
  input_dialog : Dialog?
  selection : SelectionSubmission?
}

///|
priv struct TaskState {
  items : Array[Task]
  session : String
  revision : Int
  connection : TaskConnection
  submitting : Bool
  sync_error : String
  submit_error : String
} derive(Eq)

///|
fn TaskState::initialize() -> TaskState {
  {
    items: [],
    session: "",
    revision: -1,
    connection: {
      generation: 0,
      phase: Connecting,
      retry_delay: 1_000,
      received: false,
    },
    submitting: false,
    sync_error: "",
    submit_error: "",
  }
}

///|
fn TaskState::error(self : TaskState) -> String {
  if self.sync_error.is_empty() {
    self.submit_error
  } else {
    self.sync_error
  }
}

///|
fn Task::summary(task : Task) -> String {
  match task.status {
    Queued => "Queued: \{task.description}"
    Running => "Running: \{task.description}"
    Completed(_) => "Completed: \{task.description}"
    Failed(_) => "Failed: \{task.description}"
  }
}

///|
fn latest_git_task(tasks : Array[Task], path : Path) -> Task? {
  if tasks
    .iter()
    .find_first(task => {
      task.kind is Git(request) &&
      request.path == path &&
      task.status.is_active()
    })
    is Some(task) {
    return Some(task)
  }
  tasks
  .iter()
  .find_first(task => task.kind is Git(request) && request.path == path)
}
