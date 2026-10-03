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
