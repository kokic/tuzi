///|
/// Heartbeats let clients detect broken connections. The upgraded socket
/// must remain inside this handler's lifetime.
async fn task_events(
  req : @moonback.Request,
  res : @moonback.Responder,
  tasks : TaskService,
) -> Unit {
  let conn = res.upgrade(req)
  let queue : @async.Queue[Unit] = @async.Queue::Queue(kind=@aqueue.Blocking(1))
  defer queue.close()
  let id = tasks.subscribe(queue)
  defer tasks.unsubscribe(id)
  @async.with_timeout(30_000, () => {
    conn.send_text(ToJson::to_json(tasks.snapshot()).stringify())
  })
  @async.with_task_group(root => {
    root.spawn_bg(() => {
      while true {
        ignore(conn.recv())
      }
    })
    while true {
      @async.with_timeout(15_000, () => queue.get()) catch {
        @async.TimeoutError => ()
        error => raise error
      }
      @async.with_timeout(30_000, () => {
        conn.send_text(ToJson::to_json(tasks.snapshot()).stringify())
      })
    }
  })
}
