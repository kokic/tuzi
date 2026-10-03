///|
/// Task ownership is tied to the server scope, never an HTTP connection.
priv struct TaskService {
  session : String
  mut revision : Int
  mut next_id : Int
  /// Tasks remain available for the lifetime of this server session.
  mut tasks : Array[@shared.Task]
  slots : @async.Semaphore
  /// Each subscriber retains at most one notification to read the latest state.
  mut subscribers : Array[(Int, @async.Queue[Unit])]
  mut next_subscriber : Int
}

///|
fn TaskService::new() -> TaskService {
  {
    session: @async.now().to_string(),
    revision: 0,
    next_id: 0,
    tasks: [],
    slots: @async.Semaphore(4),
    subscribers: [],
    next_subscriber: 0,
  }
}

///|
fn TaskService::subscribe(
  self : TaskService,
  queue : @async.Queue[Unit],
) -> Int {
  let id = self.next_subscriber
  self.next_subscriber += 1
  self.subscribers.push((id, queue))
  id
}

///|
fn TaskService::unsubscribe(self : TaskService, id : Int) -> Unit {
  self.subscribers = self.subscribers.filter(pair => pair.0 != id)
}

///|
/// Coalesce changes for slow subscribers without retaining obsolete snapshots.
fn TaskService::broadcast(self : TaskService) -> Unit raise {
  self.subscribers.each(pair => ignore(pair.1.try_put(())))
}

///|
fn TaskService::snapshot(self : TaskService) -> @shared.TaskSnapshot {
  { session: self.session, revision: self.revision, tasks: self.tasks, }
}

///|
/// Starting a task changes its status without reordering the activity history.
fn TaskService::start(self : TaskService, id : Int) -> Unit raise {
  self.tasks = self.tasks.map(task => {
    if task.id == id {
      { ..task, status: Running, }
    } else {
      task
    }
  })
  self.revision += 1
  self.broadcast()
}

///|
fn TaskService::finish(
  self : TaskService,
  id : Int,
  status : @shared.TaskStatus,
) -> Unit raise {
  let task = self.tasks.iter().find_first(task => task.id == id).unwrap()
  self.tasks = [{ ..task, status, }, ..self.tasks.filter(task => task.id != id)]
  self.revision += 1
  self.broadcast()
}
