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
  let history = stack.map(stack => {
    (stack.current.id, stack.current.path, stack.history)
  })
  let bookmarks = stack
    .map(stack => (stack.current.id, stack.current.path))
    .map2(model.map(model => model.bookmarks), (location, bookmarks) => {
      (location.0, location.1, bookmarks)
    })
  let active = model.map(model => model.active == idx)
  let other_path = model.map(model => model.pane_at(idx.other()).path)
  let views = stack
    .map(stack => @vector.Vector::from_array([..stack.parents, stack.current]))
    .assoc_by(
      (id, pane) => {
        let rows = pane_rows(pane, other_path, idx, emit, appearance, openers)
        // Cached ancestor views retain their rows, but only the visible view
        // mounts navigation menus and their items.
        let history_menu = history.switch_by(
          history => {
            let (current_id, path, paths) = history
            guard current_id == id else { return Val::constant(@html.nothing) }
            pane_history_menu_view(
              "pane-\{idx.index()}-view-\{id}-history",
              path,
              paths,
              idx,
              emit,
            )
          },
          by=history => {
            if history.0 == id {
              ToJson::to_json((history.1, history.2)).stringify()
            } else {
              ""
            }
          },
        )
        let bookmark_menu = bookmarks.switch_by(
          bookmarks => {
            let (current_id, path, paths) = bookmarks
            guard current_id == id else { return Val::constant(@html.nothing) }
            pane_bookmark_menu_view(
              "pane-\{idx.index()}-view-\{id}-bookmarks",
              path,
              paths,
              idx,
              emit,
            )
          },
          by=bookmarks => {
            if bookmarks.0 == id {
              ToJson::to_json((bookmarks.1, bookmarks.2)).stringify()
            } else {
              ""
            }
          },
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
        let breadcrumbs = pane
          .map(pane => (pane.path, pane.request_id))
          .switch_by(
            listing => {
              let (path, _) = listing
              breadcrumbs_view(
                path,
                id,
                idx,
                emit,
                openers,
                other_path,
                drive_menu=if supports_drives { Some(drive_menu) } else { None },
              )
            },
            by=listing => ToJson::to_json(listing).stringify(),
          )
        let sort_select = sort.switch_by(
          sort => {
            pane_sort_select(
              "pane-\{idx.index()}-view-\{id}-sort",
              idx,
              sort,
              emit,
            )
          },
          by=sort => sort.label(),
        )
        let content = pane.view8(
          filter,
          active,
          rows,
          breadcrumbs,
          sort_select,
          history_menu,
          bookmark_menu,
          (
            pane,
            filter,
            active,
            rows,
            breadcrumbs,
            sort_select,
            history_menu,
            bookmark_menu,
          ) => {
            pane.pane_view(
              idx, emit, active, filter, rows, breadcrumbs, sort_select, history_menu,
              bookmark_menu,
            )
          },
        )
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
