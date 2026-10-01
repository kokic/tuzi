///|
priv enum RequestFailure {
  Rejected(@tuzi.ApiFailure)
  Unconfirmed(String)
} derive(Eq)

///|
fn RequestFailure::message(self : RequestFailure) -> String {
  match self {
    Rejected(error) => error.message
    Unconfirmed(message) => message
  }
}

///|
fn RequestFailure::submission_message(self : RequestFailure) -> String {
  match self {
    Rejected(error) => error.message
    Unconfirmed(message) =>
      "Submission not confirmed; check Activity before trying again: " + message
  }
}

///|
/// One listing can satisfy both panes when they show the same path.
fn request_directory_listing(
  targets : Array[ListingTarget],
  path : Path,
  include_markers : Bool,
  emit : Emit[Msg],
) -> Cmd {
  request_api(
    "/api/list",
    body=ToJson::to_json(@tuzi.ListingRequest::{ path, include_markers, }),
    result => {
      emit(PaneEvent(ListLoaded(targets, path, include_markers, result)))
    },
  )
}

///|
/// Report the server response or transport failure. Mutations are never retried automatically.
fn[T : FromJson] request_api(
  path : String,
  receive : Emit[Result[T, RequestFailure]],
  body? : Json,
) -> Cmd {
  @rabbita.perform(result => receive(result), () => {
    try {
      let url = @dom.window().origin() + path
      let (response, data) = if body is Some(body) {
        @http.post(url, body, headers={ "Content-Type": "application/json" })
      } else {
        @http.get(url)
      }
      guard response.code is (200..<300) else {
        return Err(Unconfirmed("HTTP \{response.code} \{response.reason}"))
      }
      let response : @tuzi.ApiResponse[T] = @json.from_json(
        @json.parse(data.text()),
      )
      match response {
        Success(value) => Ok(value)
        Failure(error) => Err(Rejected(error))
      }
    } catch {
      error => Err(Unconfirmed(error.to_string()))
    }
  })
}
