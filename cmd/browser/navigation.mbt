///|
fn Model::open_cursor_entry(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  let data = pane.view_data(filter?=model.entry_filter())
  guard data.entries.get(data.cursor_index.unwrap_or(0)) is Some(entry) else {
    return (model, @rabbita.none)
  }
  model.open_entry(model.active, entry, emit)
}

///|
fn Model::open_entry_at_row(
  model : Model,
  idx : PaneSide,
  row : Int,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let pane = model.pane_at(idx)
  guard pane.visible_entries(filter?=model.entry_filter()).get(row)
    is Some(entry) else {
    return (model, @rabbita.none)
  }
  model.open_entry(idx, entry, emit)
}

///|
fn Model::open_entry(
  model : Model,
  idx : PaneSide,
  entry : Entry,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let path = model.pane_at(idx).path.join(Path("./\{entry.name}"))
  guard !entry.is_dir else { return model.navigate_to_directory(idx, path) }
  // When listing metadata is unavailable, let the server inspect the file.
  guard entry.size.map_or(true, size => {
    preview_content_type(path, size) is Some(_)
  }) else {
    return (
      model,
      emit(
        Toast(
          "Unsupported file format",
          Some("Unknown formats can only be opened as text when at most 1 MiB."),
          @rui.ToastDestructive,
        ),
      ),
    )
  }
  (
    model,
    @rabbita.effect(() => {
      let window = @dom.Window::from(@dom.window())
      let opened : @js.Value = window.apply_with_string("open", [
        path.file_url(),
        "_blank",
        "noopener",
      ])
      ignore(opened)
    }),
  )
}

///|
fn Path::file_url(path : Path) -> String {
  let name : String = @js.globalThis.apply_with_string("encodeURIComponent", [
    path.basename(),
  ])
  let encoded_path : String = @js.globalThis.apply_with_string(
    "encodeURIComponent",
    [path.to_string()],
  )
  "/api/file/\{name}?path=\{encoded_path}"
}

///|
fn Model::open_parent_directory(model : Model) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  let parent = pane.path.dirname()
  guard parent != pane.path else { return (model, @rabbita.none) }
  model.navigate_to_directory(model.active, parent)
}

///|
/// Explicit reloads affect only the displayed directories.
fn Model::invalidate_panes(model : Model, left~ : Bool, right~ : Bool) -> Model {
  let panes = set_pane(model.panes, Left, {
    ..model.panes.0.current,
    refresh_pending: model.panes.0.current.refresh_pending || left,
  })
  let panes = set_pane(panes, Right, {
    ..model.panes.1.current,
    refresh_pending: model.panes.1.current.refresh_pending || right,
  })
  { ..model, panes, }
}

///|
fn Model::update_panes(
  model : Model,
  msg : PaneMsg,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match msg {
    ReloadPane(idx) =>
      (
        model.invalidate_panes(left=idx == Left, right=idx == Right),
        @rabbita.none,
      )
    ListLoaded(targets, path, include_markers, result) =>
      (
        model.receive_listing(targets, path, include_markers, result),
        @rabbita.none,
      )
    GotoPath(idx, path) => model.navigate_to_directory(idx, path)
    Click(idx, row) =>
      (
        {
          ..model,
          active: idx,
          panes: set_pane(model.panes, idx, {
            ..model.pane_at(idx),
            cursor: model
            .pane_at(idx)
            .visible_entries(filter?=model.entry_filter())
            .get(row)
            .map(entry => entry.name),
          }),
        },
        @rabbita.none,
      )
    DblClick(idx, row) => model.open_entry_at_row(idx, row, emit)
    Select(idx, name) =>
      (
        {
          ..model,
          active: idx,
          panes: set_pane(
            model.panes,
            idx,
            model.pane_at(idx).toggle_entry_selection(name),
          ),
        },
        @rabbita.none,
      )
  }
}

///|
/// Apply a shared response to both panes before scheduling further work.
fn Model::receive_listing(
  model : Model,
  targets : Array[ListingTarget],
  path : Path,
  include_markers : Bool,
  result : Result[Array[Entry], RequestFailure],
) -> Model {
  targets.fold(init=model, (model, target) => {
    let { pane: idx, view_id, request_id, } = target
    let receive = (pane : Pane) => {
      guard pane.id == view_id &&
        pane.path == path &&
        pane.request_id == request_id else {
        return pane
      }
      if include_markers != (model.icons != None) {
        // A response for the previous icon mode cannot satisfy this view.
        { ..pane, loading: Unloaded, refresh_pending: true, }
      } else {
        match result {
          Ok(entries) =>
            {
              ..pane.with_entries(
                entries,
                model.sort,
                filter?=model.entry_filter(),
              ),
              loading: Ready,
            }
          Err(error) => { ..pane, loading: LoadFailed(error.message()), }
        }
      }
    }
    {
      ..model,
      panes: match idx {
        Left => (model.panes.0.map_views(receive), model.panes.1)
        Right => (model.panes.0, model.panes.1.map_views(receive))
      },
    }
  })
}

///|
/// Start at most one request per visible directory. An in-flight request is
/// allowed to finish; accumulated invalidations cause one subsequent request.
fn Model::load_pending_panes(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  guard model.startup is Started else { return (model, @rabbita.none) }
  let left = model.panes.0.current
  let right = model.panes.1.current
  let same_path = left.path == right.path
  guard !(same_path && (left.loading is Loading || right.loading is Loading)) else {
    return (model, @rabbita.none)
  }
  let reload_left = left.refresh_pending && !(left.loading is Loading)
  let reload_right = right.refresh_pending && !(right.loading is Loading)
  guard reload_left || reload_right else { return (model, @rabbita.none) }
  let left = if reload_left { left.begin_loading() } else { left }
  let right = if reload_right { right.begin_loading() } else { right }
  let command = if reload_left && reload_right && same_path {
    request_directory_listing(
      [
        { pane: Left, view_id: left.id, request_id: left.request_id, },
        { pane: Right, view_id: right.id, request_id: right.request_id, },
      ],
      left.path,
      model.icons != None,
      emit,
    )
  } else {
    @rabbita.batch(
      [
        ..if reload_left {
          [
            request_directory_listing(
              [{ pane: Left, view_id: left.id, request_id: left.request_id, }],
              left.path,
              model.icons != None,
              emit,
            ),
          ]
        },
        ..if reload_right {
          [
            request_directory_listing(
              [
                {
                  pane: Right,
                  view_id: right.id,
                  request_id: right.request_id,
                },
              ],
              right.path,
              model.icons != None,
              emit,
            ),
          ]
        },
      ],
    )
  }
  (
    {
      ..model,
      panes: set_pane(set_pane(model.panes, Left, left), Right, right),
    },
    command,
  )
}

///|
fn Model::scroll_to_cursor(model : Model) -> Cmd {
  let pane = model.pane_at(model.active)
  guard pane.cursor is Some(_) else { return @rabbita.none }
  let row = pane.cursor_index(filter?=model.entry_filter())
  @nav.scroll_to("pane-\{model.active.index()}-view-\{pane.id}-row-\{row}")
}
