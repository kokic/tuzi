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
    TaskOutputOpen(id) => {
      guard model.jobs.items.any(task => {
        task.id == id && task.history_output() is Some(_)
      }) else {
        return (model, @rabbita.none)
      }
      ({ ..model, dialog: TaskOutput(id), dialog_error: "", }, @rabbita.none)
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
        TaskDetails(_) | TaskOutput(_) => None
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
