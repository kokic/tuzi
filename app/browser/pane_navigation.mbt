///|
fn Model::open_cursor_entry(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  guard model.cursor_open_target() is Some(target) else {
    return (model, @rabbita.none)
  }
  model.open_default(target, emit)
}

///|
fn Model::open_entry_at_row(
  model : Model,
  idx : PaneSide,
  row : Int,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let pane = model.pane_at(idx)
  guard pane.visible_entries(filter?=model.entry_filter(idx)).get(row)
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
  model.open_default({ pane: idx, path, entry, }, emit)
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
            .visible_entries(filter?=model.entry_filter(idx))
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
fn Model::scroll_to_cursor(model : Model) -> Cmd {
  let pane = model.pane_at(model.active)
  guard pane.cursor is Some(_) else { return @rabbita.none }
  let row = pane.cursor_index(filter?=model.entry_filter(model.active))
  let id = "pane-\{model.active.index()}-view-\{pane.id}-row-\{row}"
  @cmd.custom_cmd(kind=AfterRender, _ => {
    guard @dom.document().get_element_by_id(id).to_option() is Some(node) else {
      return
    }
    node.scroll_into_view_with_options(
      block="nearest",
      inline="nearest",
      container="nearest",
    )
  })
}
