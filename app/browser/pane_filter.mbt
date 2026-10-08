///|
fn Model::filter_text(model : Model, idx : PaneSide) -> String {
  match idx {
    Left => model.filters.0
    Right => model.filters.1
  }
}

///|
fn Model::entry_filter(model : Model, idx : PaneSide) -> String? {
  let filter = model.filter_text(idx)
  guard !filter.is_empty() else { None }
  Some(filter)
}

///|
fn Model::with_filter(model : Model, idx : PaneSide, text : String) -> Model {
  let filter : String? = if text.is_empty() { None } else { Some(text) }
  {
    ..model,
    filters: match idx {
      Left => (text, model.filters.1)
      Right => (model.filters.0, text)
    },
    panes: match idx {
      Left =>
        (
          model.panes.0.map_views(pane => pane.with_filter(filter?)),
          model.panes.1,
        )
      Right =>
        (
          model.panes.0,
          model.panes.1.map_views(pane => pane.with_filter(filter?)),
        )
    },
  }
}

///|
fn Model::cycle_sort_order(model : Model) -> Model {
  let sort = model.sort.next()
  {
    ..model,
    sort,
    panes: (
      model.panes.0.map_views(pane => {
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter(Left))
      }),
      model.panes.1.map_views(pane => {
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter(Right))
      }),
    ),
  }
}

///|
fn Pane::with_filter(pane : Pane, filter? : String) -> Pane {
  let entries = pane.visible_entries(filter?)
  let cursor = if entries.any(entry => Some(entry.name) == pane.cursor) {
    pane.cursor
  } else {
    entries.get(0).map(entry => entry.name)
  }
  { ..pane, cursor, }
}

///|
/// Entries are sorted when stored. With no filter, reuse them without allocation.
fn Pane::visible_entries(pane : Pane, filter? : String) -> Array[Entry] {
  guard filter is Some(query) else { return pane.entries }
  pane.entries.filter(entry => entry.name.contains(query))
}

///|
fn Model::update_filter_focus(
  model : Model,
  idx : PaneSide,
  focused : Bool,
) -> (Model, Cmd) {
  let model = if focused {
    { ..model, active: idx, editing: true, }
  } else if model.active == idx {
    { ..model, editing: false, }
  } else {
    model
  }
  (model, @rabbita.none)
}
