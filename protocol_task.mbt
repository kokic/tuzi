///|
pub(all) enum TaskKind {
  File(FileOperation)
  Git(GitRequest)
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum TaskStatus {
  Queued
  Running
  Completed(String)
  Failed(ApiFailure)
} derive(Eq, ToJson, FromJson)

///|
/// Queued and running tasks both remain active until they have a result.
pub fn TaskStatus::is_active(self : TaskStatus) -> Bool {
  match self {
    Queued | Running => true
    Completed(_) | Failed(_) => false
  }
}

///|
pub(all) struct Task {
  id : Int
  kind : TaskKind
  description : String
  status : TaskStatus
} derive(Eq, ToJson, FromJson)

///|
/// Complete task history for the current server session.
pub(all) struct TaskSnapshot {
  session : String
  revision : Int
  tasks : Array[Task]
} derive(Eq, ToJson, FromJson)

///|
pub extend TaskKind with Eq::{equal, not_equal}

///|
pub extend TaskKind with ToJson::{to_json}

///|
pub extend TaskKind with FromJson::{from_json}

///|
pub extend TaskStatus with Eq::{equal, not_equal}

///|
pub extend TaskStatus with ToJson::{to_json}

///|
pub extend TaskStatus with FromJson::{from_json}

///|
pub extend Task with Eq::{equal, not_equal}

///|
pub extend Task with ToJson::{to_json}

///|
pub extend Task with FromJson::{from_json}

///|
pub extend TaskSnapshot with Eq::{equal, not_equal}

///|
pub extend TaskSnapshot with ToJson::{to_json}

///|
pub extend TaskSnapshot with FromJson::{from_json}

///|
/// Submission ids belong to one server session and must not be reused after a restart.
/// Results correspond to submitted operations in order. Rejected items have no id.
pub(all) struct TaskSubmission {
  session : String
  results : Array[ApiResponse[Int]]
} derive(ToJson, FromJson)

///|
pub extend TaskSubmission with ToJson::{to_json}

///|
pub extend TaskSubmission with FromJson::{from_json}

///|
/// Directories whose immediate entries may change, including partial failure.
/// Callers must account separately for metadata in parent listings and for
/// subtrees created, removed, moved, or changed by a Git checkout.
pub fn TaskKind::affected_directories(self : TaskKind) -> Array[Path] {
  match self {
    File(Delete(target~)) => [target.dirname()]
    File(Rename(source~, ..)) => [source.dirname()]
    File(CreateFile(parent~, ..)) | File(Mkdir(parent~, ..)) => [parent]
    File(Zip(directory~, ..)) => [directory]
    File(Unzip(destination~, ..)) => [destination.dirname(), destination]
    File(Copy(destination~, ..)) => [destination.dirname()]
    File(Move(source~, destination~)) =>
      [source.dirname(), destination.dirname()]
    File(EditLink(source~, destination~, ..)) =>
      [source.dirname(), destination.dirname(), source, destination]
    Git(request) => [request.path.dirname()]
  }
}
