///|
priv enum TaskConnectionPhase {
  Connecting
  Connected
  WaitingToReconnect
} derive(Eq)

///|
priv struct TaskConnection {
  generation : Int
  phase : TaskConnectionPhase
  retry_delay : Int
  received : Bool
} derive(Eq)

///|
fn task_socket_cmd(generation : Int, emit : Emit[Msg]) -> Cmd {
  @rabbita.batch([
    @websocket.connect(
      "tuzi-tasks",
      "/api/tasks/events",
      on_event=emit.map(event => TaskEvent(TaskSocket(generation, event))),
      failed=emit.map(error => TaskEvent(TaskSocketFailed(generation, error))),
    ),
    @rabbita.delay(emit(TaskEvent(TaskConnectionCheck(generation))), 30_000),
  ])
}

///|
/// One ordered stream owns task snapshots. Generation checks reject callbacks
/// from replaced sockets; HTTP responses never replace this stream's state.
fn Model::handle_task_socket(
  model : Model,
  generation : Int,
  event : @websocket.Event,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let connection = model.jobs.connection
  guard generation == connection.generation &&
    connection.phase != WaitingToReconnect else {
    return (model, @rabbita.none)
  }
  match event {
    Opened =>
      (
        {
          ..model,
          jobs: {
            ..model.jobs,
            connection: { ..connection, phase: Connected, },
          },
        },
        @rabbita.none,
      )
    Message(text) => {
      let snapshot : @tuzi.TaskSnapshot = @json.from_json(@json.parse(text)) catch {
        error =>
          return model.retry_task_socket(generation, error.to_string(), emit)
      }
      let model = {
        ..model,
        jobs: {
          ..model.jobs,
          connection: { ..connection, retry_delay: 1_000, received: true, },
        },
      }
      model.receive_tasks(snapshot, emit)
    }
    Closed(_) | Errored =>
      model.retry_task_socket(generation, "Task connection lost", emit)
  }
}

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
