///|
fn pane_stack_view(
  model : Val[Model],
  idx : PaneSide,
  emit : Emit[Msg],
  appearance : EntryAppearance,
  openers : @tuzi.OpenRegistry?,
  supports_drives : Bool,
) -> Val[Html] {
  let stack = model.map(model => {
    match idx {
      Left => model.panes.0
      Right => model.panes.1
    }
  })
  let visible_id = stack.map(stack => stack.current.id)
  let filter = model.map(model => model.entry_filter(idx))
  let sort = stack.map(stack => stack.sort)
  let active = model.map(model => model.active == idx)
  let other_path = model.map(model => model.pane_at(idx.other()).path)
  let views = stack
    .map(stack => @vector.Vector::from_array([..stack.parents, stack.current]))
    .assoc_by(
      (id, pane) => {
        let rows = pane_rows(
          pane, filter, other_path, idx, emit, appearance, openers,
        )
        let drive_menu = pane
          .map(pane => pane.path)
          .switch_by(
            path => {
              guard supports_drives else { return Val::constant(@html.nothing) }
              let (_, root) = breadcrumb_segments(path)[0]
              drive_menu_view(
                "pane-\{idx.index()}-view-\{id}-drives",
                root,
                path,
                idx,
                emit,
              )
            },
            by=path => path.to_string(),
          )
        let content = pane.view6(filter, sort, active, rows, drive_menu, (
          pane,
          filter,
          sort,
          active,
          rows,
          drive_menu,
        ) => {
          pane.pane_view(
            pane.view_data(filter?),
            idx,
            emit,
            sort,
            active,
            filter,
            rows,
            drive_menu=if supports_drives { Some(drive_menu) } else { None },
          )
        })
        let visible = visible_id.map(current => current == id)
        visible.map2(content, (visible, content) => {
          (
            id.to_string(),
            div(
              attrs=@html.Attrs::build().inert(!visible),
              style=[
                "position: absolute",
                "inset: 0",
                "display: flex",
                "min-width: 0",
                "min-height: 0",
                ..if !visible {
                  ["content-visibility: hidden"]
                },
              ],
              content,
            ),
          )
        })
      },
      by=pane => pane.id,
    )
  views.view(views => {
    let children : Map[String, Html] = Map::from_iter(views.iter())
    div(
      id="pane-\{idx.index()}",
      style=["position: relative", "flex: 1", "min-width: 0", "min-height: 0"],
      children,
    )
  })
}
