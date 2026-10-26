///|
priv enum ProgressState {
  Submitting
  Rejected(@tuzi.ApiFailure)
  Tracking(Int32, TaskStatus?)
} derive(Eq)

///|
priv struct ProgressItem {
  operation : FileOperation
  state : ProgressState
} derive(Eq)

///|
priv struct ProgressBatch {
  items : Array[ProgressItem]
  session : String
  error : RequestFailure?
} derive(Eq)

///|
fn ProgressBatch::initialize(
  operations : Array[FileOperation],
) -> ProgressBatch {
  {
    items: operations.map(operation => { operation, state: Submitting, }),
    session: "",
    error: None,
  }
}

///|
fn ProgressBatch::submitted(
  self : ProgressBatch,
  result : Result[@tuzi.TaskSubmission, RequestFailure],
) -> ProgressBatch {
  match result {
    Err(error) => { ..self, error: Some(error), }
    Ok(submission) =>
      {
        ..self,
        session: submission.session,
        items: self.items.mapi((index, item) => {
          ..item,
          state: match submission.results[index] {
            Success(id) => Tracking(id, None)
            Failure(error) => Rejected(error)
          },
        }),
      }
  }
}

///|
fn ProgressState::receive(
  self : ProgressState,
  statuses : Map[Int32, TaskStatus],
) -> ProgressState {
  guard self is Tracking(id, _) else { return self }
  if statuses.get(id) is Some(status) {
    return Tracking(id, Some(status))
  }
  self
}

///|
fn Model::refresh_progress(model : Model) -> Model {
  guard model.dialog is Progress(batch) &&
    !batch.session.is_empty() &&
    batch.session == model.jobs.session else {
    return model
  }
  let statuses = Map::from_iter(
    model.jobs.items.iter().map(task => (task.id, task.status)),
  )
  let batch = {
    ..batch,
    items: batch.items.map(item => {
      ..item,
      state: item.state.receive(statuses),
    }),
  }
  let completed = batch.error is None &&
    !batch.items.is_empty() &&
    batch.items.all(item => item.state is Tracking(_, Some(Completed(_))))
  { ..model, dialog: if completed { None } else { Progress(batch) }, }
}
