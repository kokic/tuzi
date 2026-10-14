///|
fn Model::move_active_pane_cursor(model : Model, delta : Int32) -> Model {
  {
    ..model,
    panes: set_pane(
      model.panes,
      model.active,
      model.pane_at(model.active).move_cursor(delta),
    ),
  }
}

///|
fn Model::toggle_selection_and_advance_cursor(model : Model) -> Model {
  {
    ..model,
    panes: set_pane(
      model.panes,
      model.active,
      model.pane_at(model.active).toggle_cursor_selection(),
    ),
  }
}

///|
fn Model::switch_active_pane(model : Model) -> Model {
  { ..model, active: model.active.other(), editing: false, }
}
