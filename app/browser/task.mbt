///|
priv enum TaskMsg {
  TasksSubmitted(
    SubmissionContext,
    Result[@tuzi.TaskSubmission, RequestFailure]
  )
  TaskOpen(Int)
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
/// Only a confirmed rejection is safe to return to an editable input dialog.
fn submission_rejected(
  result : Result[@tuzi.TaskSubmission, RequestFailure],
) -> Bool {
  match result {
    Ok(submission) => submission.results.all(item => item is Failure(_))
    Err(Rejected(_)) => true
    Err(Unconfirmed(_)) => false
  }
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
fn Model::update_tasks(
  model : Model,
  msg : TaskMsg,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match msg {
    TasksSubmitted(context, result) => {
      let submit_error = match result {
        Ok(submission) =>
          submission.results
          .filter_map(result => {
            match result {
              Success(_) => None
              Failure(error) => Some(error.message)
            }
          })
          .join("\n")
        Err(error) => error.submission_message()
      }
      let model = {
        ..model,
        jobs: { ..model.jobs, submitting: false, submit_error, },
      }
      match context {
        Background => (model, @rabbita.none)
        Files(submission) =>
          (
            model.finish_file_submission(submission, result).refresh_progress(),
            @rabbita.none,
          )
        GitRename(dialog_revision~, context~, input_dialog~) => {
          guard model.dialog_revision == dialog_revision else {
            return (model, @rabbita.none)
          }
          if submission_rejected(result) {
            return (
              {
                ..model,
                dialog: input_dialog,
                dialog_error: model.jobs.submit_error,
              },
              @rabbita.none,
            )
          }
          guard result is Ok(_) else { return (model, @rabbita.none) }
          model.refresh_git(context.entry.id, emit)
        }
      }
    }
    TaskOpen(id) => {
      guard model.jobs.items.any(task => task.id == id) else {
        return (model, @rabbita.none)
      }
      ({ ..model, dialog: TaskDetails(id), dialog_error: "", }, @rabbita.none)
    }
    TaskSocket(generation, event) =>
      model.handle_task_socket(generation, event, emit)
    TaskSocketFailed(generation, error) =>
      model.retry_task_socket(generation, error, emit)
    TaskReconnect(generation) => model.reconnect_tasks(generation, emit)
    TaskConnectionCheck(generation) =>
      model.check_task_connection(generation, emit)
  }
}

///|
/// Capture the originating UI before sending. Acceptance is handled by the reply.
fn Model::start_file_operations(
  model : Model,
  operations : Array[FileOperation],
  emit : Emit[Msg],
  input_dialog? : Dialog,
  selection? : SelectionSubmission,
) -> (Model, Cmd)? {
  let progress = ProgressBatch::initialize(operations)
  let dialog : Dialog = Progress(progress)
  let dialog_revision = model.dialog_revision +
    (if dialog == model.dialog { 0 } else { 1 })
  let model = { ..model, dialog, dialog_error: "", }
  model.submit_tasks(
    operations.map(operation => TaskKind::File(operation)),
    emit,
    context=Files({ dialog_revision, progress, input_dialog, selection, }),
  )
}

///|
fn Model::finish_file_submission(
  model : Model,
  context : FileSubmission,
  result : Result[@tuzi.TaskSubmission, RequestFailure],
) -> Model {
  let model = context.selection.map_or(model, selection => {
    model.clear_accepted_selection(selection, result)
  })
  guard model.dialog_revision == context.dialog_revision else { return model }
  if submission_rejected(result) && context.input_dialog is Some(dialog) {
    return { ..model, dialog, dialog_error: model.jobs.submit_error, }
  }
  {
    ..model,
    dialog: Progress(context.progress.submitted(result)),
    dialog_error: "",
  }
}

///|
fn Model::submit_tasks(
  model : Model,
  kinds : Array[TaskKind],
  emit : Emit[Msg],
  context? : SubmissionContext = Background,
) -> (Model, Cmd)? {
  guard !model.jobs.submitting && !kinds.is_empty() else { return None }
  Some(
    (
      { ..model, jobs: { ..model.jobs, submitting: true, submit_error: "", }, },
      request_api("/api/tasks", body=kinds.to_json(), result => {
        emit(TaskEvent(TasksSubmitted(context, result)))
      }),
    ),
  )
}

///|
fn TaskState::receive(
  self : TaskState,
  snapshot : @tuzi.TaskSnapshot,
) -> (TaskState, Array[Task]) {
  guard self.session != snapshot.session || snapshot.revision > self.revision else {
    return ({ ..self, sync_error: "", }, [])
  }
  let same_session = self.session == snapshot.session
  let previous_statuses = if same_session {
    Map::from_iter(self.items.iter().map(task => (task.id, task.status)))
  } else {
    {}
  }
  let changed = snapshot.tasks.filter(task => {
    !task.status.is_active() &&
    previous_statuses.get(task.id) != Some(task.status)
  })
  (
    {
      ..self,
      items: snapshot.tasks,
      session: snapshot.session,
      revision: snapshot.revision,
      sync_error: "",
    },
    changed,
  )
}

///|
fn Model::receive_tasks(
  model : Model,
  snapshot : @tuzi.TaskSnapshot,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let (jobs, changed) = model.jobs.receive(snapshot)
  let restarted = !model.jobs.session.is_empty() &&
    model.jobs.session != jobs.session
  let model = {
    ..model,
    jobs,
    // Keep a batch already acknowledged by the new server, but discard
    // monitors whose ids belong to the previous session.
    dialog: if restarted {
      match model.dialog {
        TaskDetails(_) => None
        Progress(batch) if batch.session != jobs.session => None
        other => other
      }
    } else {
      model.dialog
    },
  }
  let model = model.refresh_progress()
  // Retained ancestors are marked too, but only visible views are reloaded.
  let affected = path => {
    restarted || changed.any(task => task.kind.affects_listing(path))
  }
  let model = {
    ..model,
    panes: (
      model.panes.0.invalidate(affected),
      model.panes.1.invalidate(affected),
    ),
  }
  guard model.dialog is GitInfo(context) &&
    (
      restarted ||
      changed.any(task => {
        task.kind is Git(request) && request.path == context.entry.path
      })
    ) else {
    return (model, @rabbita.none)
  }
  model.refresh_git(context.entry.id, emit)
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
