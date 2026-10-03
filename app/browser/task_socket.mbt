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
