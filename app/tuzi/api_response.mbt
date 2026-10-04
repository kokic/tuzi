///|
priv suberror RequestError {
  InvalidRequest(String)
}

///|
fn[T : @json.FromJson] decode_json(value : Json) -> T raise RequestError {
  @json.from_json(value) catch {
    error => raise InvalidRequest(error.to_string())
  }
}

///|
async fn[T : @json.FromJson] decode_request(req : @moonback.Request) -> T {
  let text = req.body.text()
  let value = @json.parse(text) catch {
    error => raise InvalidRequest(error.to_string())
  }
  decode_json(value)
}

///|
async fn[T : ToJson] respond(
  res : @moonback.Responder,
  action : async () -> T,
) -> Unit {
  let response : @shared.ApiResponse[T] = Success(action()) catch {
    error => Failure(api_failure(error))
  }
  res.send_json(ToJson::to_json(response))
}

///|
fn api_failure(error : Error) -> @shared.ApiFailure {
  let (code, message) : (@shared.ApiErrorCode, String) = match error {
    InvalidRequest(message) => (InvalidRequest, message)
    OpenError::UnknownOpener(_) | OpenError::DefaultNotListed(_) as error =>
      (InvalidRequest, Show::to_string(error))
    OpenError::NotApplicable(_) | OpenError::UnsupportedTarget(_) as error =>
      (Unsupported, Show::to_string(error))
    OpenError::ProgramMissing(_) as error => (NotFound, Show::to_string(error))
    FileError::InvalidName(_) as error => (InvalidName, Show::to_string(error))
    ArchiveError::InvalidName(_) as error =>
      (InvalidName, Show::to_string(error))
    FileError::InvalidTarget(_) as error =>
      (InvalidTarget, Show::to_string(error))
    OutputIsInput(_) as error => (InvalidTarget, Show::to_string(error))
    FileError::UnsupportedEntry(_) as error =>
      (Unsupported, Show::to_string(error))
    ArchiveError::UnsupportedEntry(_) as error =>
      (Unsupported, Show::to_string(error))
    CleanupFailed(_, _) | SourceRemovalFailed(_, _, _) as error =>
      (PartialFailure, Show::to_string(error))
    LinkError::AbsolutePathRequired(_) as error =>
      (InvalidTarget, Show::to_string(error))
    LinkError::RecoveryFailed(_, _) as error =>
      (PartialFailure, Show::to_string(error))
    LinkError::LinkCommandFailed(_, _, _) as error =>
      (Io, Show::to_string(error))
    EmptySelection | InvalidCompressionLevel(_) as error =>
      (InvalidRequest, Show::to_string(error))
    ExtractionError::UnsafePath(_) as error =>
      (InvalidName, Show::to_string(error))
    ExtractionError::ChecksumMismatch(_) as error =>
      (InvalidRequest, Show::to_string(error))
    @zip.ZipError(UnsupportedCompression(_) | UnsupportedFeature, message) =>
      (Unsupported, message)
    @zip.ZipError(_, message) => (InvalidRequest, message)
    GitBusy => (Busy, "A Git operation is already running for this repository")
    GitMissing as error => (GitUnavailable, Show::to_string(error))
    InvalidGitPath(_)
    | InvalidLocalReference(_)
    | InvalidSwitchReference(_) as error =>
      (InvalidRequest, Show::to_string(error))
    CommandFailed(..) as error => (GitFailed, Show::to_string(error))
    @os_error.OSError(_, ..) as error if error.is_EEXIST() =>
      (Conflict, error.to_string())
    @os_error.OSError(_, ..) as error if error.is_EACCES() =>
      (PermissionDenied, error.to_string())
    @os_error.OSError(_, ..) as error if error.is_ENOENT() =>
      (NotFound, error.to_string())
    _ => (Io, error.to_string())
  }
  { code, message, }
}
