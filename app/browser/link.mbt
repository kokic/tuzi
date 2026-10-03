///|
priv struct LinkFields {
  path : String
  target : String?
} derive(Eq)

///|
fn Dialog::map_info(
  self : Dialog,
  update : (InfoContext) -> InfoContext,
) -> Dialog {
  match self {
    Info(context) => Info(update(context))
    GitInfo(context) => GitInfo({ ..context, entry: update(context.entry), })
    other => other
  }
}

///|
fn request_link_target(context : InfoContext, emit : Emit[Msg]) -> Cmd {
  request_api(
    "/api/link",
    body=ToJson::to_json(@tuzi.DirectoryRequest::{ path: context.path, }),
    result => emit(LinkTargetLoaded(context.id, result)),
  )
}

///|
fn Model::update_link_fields(
  model : Model,
  update : (LinkFields) -> LinkFields,
) -> Model {
  {
    ..model,
    dialog: model.dialog.map_info(context => {
      ..context,
      link: context.link.map(update),
    }),
    dialog_error: "",
  }
}

///|
fn Model::receive_link_target(
  model : Model,
  request_id : Int,
  result : Result[Path, RequestFailure],
) -> Model {
  let context = match model.dialog {
    Info(context) => context
    GitInfo(context) => context.entry
    _ => return model
  }
  guard context.id == request_id && context.link is Some({ target: None, .. }) else {
    return model
  }
  match result {
    Ok(target) =>
      model.update_link_fields(fields => {
        ..fields,
        target: Some(target.to_string()),
      })
    Err(error) => { ..model, dialog_error: error.message(), }
  }
}

///|
fn Model::submit_info_link(
  model : Model,
  context : InfoContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard context.link is Some(fields) else { return (model, @rabbita.none) }
  guard !fields.path.is_empty() &&
    fields.target is Some(target) &&
    !target.is_empty() else {
    return (
      {
        ..model,
        dialog_error: "Enter the full link path and full target path",
      },
      @rabbita.none,
    )
  }
  let parse = path => {
    if model.supports_drive_selection {
      Path::from_windows(path)
    } else {
      Path(path)
    }
  }
  model
  .start_file_operations(
    [
      EditLink(
        source=context.path,
        destination=parse(fields.path),
        target=parse(target),
      ),
    ],
    emit,
    input_dialog=model.dialog,
  )
  .unwrap_or((model, @rabbita.none))
}
