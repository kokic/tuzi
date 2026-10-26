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
pub fn TaskStatus::is_active(self : TaskStatus) -> Bool {
  match self {
    Queued | Running => true
    Completed(_) | Failed(_) => false
  }
}

///|
pub(all) struct Task {
  id : Int32
  kind : TaskKind
  description : String
  status : TaskStatus
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct TaskSnapshot {
  session : String
  revision : Int32
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
pub(all) struct TaskSubmission {
  session : String
  results : Array[ApiResponse[Int32]]
} derive(ToJson, FromJson)

///|
pub extend TaskSubmission with ToJson::{to_json}

///|
pub extend TaskSubmission with FromJson::{from_json}
