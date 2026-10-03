///|
using @path {type Path}

///|
/// Existing entries are identified by their full paths. New names identify one
/// child of the given parent; rename stays in the source directory, and ZIP
/// selections and output stay in one directory.
pub(all) enum FileOperation {
  Delete(target~ : Path)
  Rename(source~ : Path, new_name~ : String)
  EditLink(source~ : Path, destination~ : Path, target~ : Path)
  Zip(
    directory~ : Path,
    names~ : Array[String],
    output_name~ : String,
    level~ : Int
  )
  Unzip(source~ : Path, destination~ : Path)
  CreateFile(parent~ : Path, name~ : String)
  Mkdir(parent~ : Path, name~ : String)
  Copy(source~ : Path, destination~ : Path)
  Move(source~ : Path, destination~ : Path)
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum GitOperation {
  Pull
  Push
  Switch(String)
  DeleteBranch(String)
  RenameBranch(String, String)
  Prune
} derive(Eq, ToJson, FromJson)

///|
pub fn GitOperation::name(self : GitOperation) -> String {
  match self {
    Pull => "pull"
    Push => "push"
    Switch(_) => "switch"
    DeleteBranch(_) => "delete-branch"
    RenameBranch(_, _) => "rename-branch"
    Prune => "prune"
  }
}

///|
/// JSON request endpoints use this envelope for application results.
/// File responses and WebSocket frames use their own formats.
pub(all) enum ApiResponse[T] {
  Success(T)
  Failure(ApiFailure)
} derive(ToJson, FromJson)

///|
pub(all) enum ApiErrorCode {
  InvalidRequest
  InvalidName
  InvalidTarget
  Conflict
  Unsupported
  PermissionDenied
  NotFound
  PartialFailure
  Busy
  Io
  GitUnavailable
  GitFailed
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct ApiFailure {
  code : ApiErrorCode
  message : String
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum StartupMode {
  OpenDirectory
  RestoreHistory
} derive(ToJson, FromJson)

///|
pub(all) struct ServerConfig {
  base : Path
  startup : StartupMode
  theme : Theme
  icons : IconMode
  openers : OpenRegistry
  supports_drive_selection : Bool
} derive(ToJson, FromJson)

///|
pub(all) struct DirectoryRequest {
  path : Path
} derive(ToJson, FromJson)

///|
pub(all) struct GitRequest {
  path : Path
  operation : GitOperation
} derive(Eq, ToJson, FromJson)

///|
pub extend FileOperation with ToJson::{to_json}

///|
pub extend FileOperation with FromJson::{from_json}

///|
pub extend FileOperation with Eq::{equal, not_equal}

///|
pub extend GitOperation with ToJson::{to_json}

///|
pub extend GitOperation with FromJson::{from_json}

///|
pub extend GitOperation with Eq::{equal, not_equal}

///|
pub extend ApiResponse with ToJson::{to_json}

///|
pub extend ApiResponse with FromJson::{from_json}

///|
pub extend ApiErrorCode with ToJson::{to_json}

///|
pub extend ApiErrorCode with FromJson::{from_json}

///|
pub extend ApiErrorCode with Eq::{equal, not_equal}

///|
pub extend ApiFailure with ToJson::{to_json}

///|
pub extend ApiFailure with FromJson::{from_json}

///|
pub extend ApiFailure with Eq::{equal, not_equal}

///|
pub extend StartupMode with ToJson::{to_json}

///|
pub extend StartupMode with FromJson::{from_json}

///|
pub extend ServerConfig with ToJson::{to_json}

///|
pub extend ServerConfig with FromJson::{from_json}

///|
pub extend DirectoryRequest with ToJson::{to_json}

///|
pub extend DirectoryRequest with FromJson::{from_json}

///|
pub extend GitRequest with ToJson::{to_json}

///|
pub extend GitRequest with FromJson::{from_json}

///|
pub extend GitRequest with Eq::{equal, not_equal}

///|
pub fn FileOperation::description(operation : FileOperation) -> String {
  match operation {
    Delete(target~) => "delete \{target}"
    Rename(source~, new_name~) =>
      "rename \{source} -> \{source.dirname().join(Path("./\{new_name}"))}"
    EditLink(source~, destination~, target~) =>
      "edit link \{source} -> \{destination} (target: \{target})"
    Zip(directory~, output_name~, ..) =>
      "compress \{directory.join(Path("./\{output_name}"))}"
    Unzip(source~, destination~) => "extract \{source} -> \{destination}"
    CreateFile(parent~, name~) =>
      "create file \{parent.join(Path("./\{name}"))}"
    Mkdir(parent~, name~) => "create \{parent.join(Path("./\{name}"))}"
    Copy(source~, destination~) => "copy \{source} -> \{destination}"
    Move(source~, destination~) => "move \{source} -> \{destination}"
  }
}

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
pub(all) struct ListingRequest {
  path : Path
  include_markers : Bool
} derive(ToJson, FromJson)

///|
pub extend ListingRequest with ToJson::{to_json}

///|
pub extend ListingRequest with FromJson::{from_json}

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
