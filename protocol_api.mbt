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
