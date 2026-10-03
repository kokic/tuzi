///|
/// Error and close may both fire for one failure. Only the first schedules a
/// retry, and a failed connection backs off up to thirty seconds.
fn Model::retry_task_socket(
  model : Model,
  generation : Int,
  error : String,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let connection = model.jobs.connection
  guard generation == connection.generation &&
    connection.phase != WaitingToReconnect else {
    return (model, @rabbita.none)
  }
  (
    {
      ..model,
      jobs: {
        ..model.jobs,
        connection: {
          ..connection,
          phase: WaitingToReconnect,
          retry_delay: (connection.retry_delay * 2).min(30_000),
        },
        sync_error: "\{error}; reconnecting…",
      },
    },
    @rabbita.batch([
      @websocket.close("tuzi-tasks"),
      @rabbita.delay(
        emit(TaskEvent(TaskReconnect(generation))),
        connection.retry_delay,
      ),
    ]),
  )
}

///|
fn Model::reconnect_tasks(
  model : Model,
  generation : Int,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let connection = model.jobs.connection
  guard generation == connection.generation &&
    connection.phase == WaitingToReconnect else {
    return (model, @rabbita.none)
  }
  let connection = {
    ..connection,
    generation: generation + 1,
    phase: Connecting,
    received: false,
  }
  (
    { ..model, jobs: { ..model.jobs, connection, }, },
    task_socket_cmd(connection.generation, emit),
  )
}

///|
/// The server sends a snapshot at least every fifteen seconds. Keep one
/// watchdog per connection rather than scheduling a timer for every message.
fn Model::check_task_connection(
  model : Model,
  generation : Int,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let connection = model.jobs.connection
  guard generation == connection.generation &&
    connection.phase != WaitingToReconnect else {
    return (model, @rabbita.none)
  }
  guard connection.received else {
    return model.retry_task_socket(
      generation, "Task connection timed out", emit,
    )
  }
  (
    {
      ..model,
      jobs: { ..model.jobs, connection: { ..connection, received: false, }, },
    },
    @rabbita.delay(emit(TaskEvent(TaskConnectionCheck(generation))), 30_000),
  )
}
