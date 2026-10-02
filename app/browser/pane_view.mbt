///|
#cfg(target="js")
fn allow_drop(drag : @dom.DragEvent) -> Cmd {
  drag.prevent_default()
  @rabbita.none
}

///|
fn panes_view(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  model
  .map(model => (model.icons, model.openers))
  .switch_by(
    configuration => {
      let (icons, openers) = configuration
      pane_stack_view(model, Left, emit, icons, openers).view2(
        pane_stack_view(model, Right, emit, icons, openers),
        (left, right) => div(id="panes", style=panes_style(), [left, right]),
      )
    },
    by=configuration => ToJson::to_json(configuration).stringify(),
  )
}

///|
fn pane_stack_view(
  model : Val[Model],
  idx : PaneSide,
  emit : Emit[Msg],
  icons : IconMode,
  openers : @tuzi.OpenRegistry?,
) -> Val[Html] {
  let stack = model.map(model => {
    match idx {
      Left => model.panes.0
      Right => model.panes.1
    }
  })
  let visible_id = stack.map(stack => stack.current.id)
  let filter = model.map(model => model.entry_filter())
  let sort = model.map(model => model.sort)
  let active = model.map(model => model.active == idx)
  let views = stack
    .map(stack => @vector.Vector::from_array([..stack.parents, stack.current]))
    .assoc_by(
      (id, pane) => {
        let rows = pane_rows(pane, filter, idx, emit, icons, openers)
        let content = pane.view5(filter, sort, active, rows, (
          pane,
          filter,
          sort,
          active,
          rows,
        ) => {
          pane.pane_view(pane.view_data(filter?), idx, emit, sort, active, rows)
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
                if visible {
                  "content-visibility: auto"
                } else {
                  "content-visibility: hidden"
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

///|
fn Pane::pane_view(
  pane : Pane,
  data : PaneViewData,
  idx : PaneSide,
  emit : Emit[Msg],
  sort : SortMode,
  active : Bool,
  rows : Html,
) -> Html {
  let sort_label = match sort {
    Name => "name"
    Size => "size"
    Time => "time"
  }
  div(id="pane-\{idx.index()}-view-\{pane.id}", style=pane_style(active), {
    "header": breadcrumbs_view(
      pane.path,
      sort_label,
      idx,
      emit,
      pane_header_style(active),
    ),
    "status": fragment(
      match pane.loading {
        Unloaded | Loading =>
          [
            @rui.field_description(
              style=pane_status_style(),
              "Loading directory…",
            ),
          ]
        LoadFailed(error) =>
          [
            div(style=pane_status_style(), [
              @rui.field_error(error),
              @rui.button(
                style=[UI_FONT_STYLE],
                variant=Outline,
                on_click=emit(PaneEvent(ReloadPane(idx))),
                "Retry",
              ),
            ]),
          ]
        Ready =>
          if pane.entries.is_empty() {
            [
              @rui.field_description(
                style=pane_status_style(),
                "Empty directory",
              ),
            ]
          } else {
            []
          }
      },
    ),
    "entries": rows,
    "details": data.entry_details_view(),
  })
}

///|
fn breadcrumbs_view(
  path : Path,
  sort_label : String,
  idx : PaneSide,
  emit : Emit[Msg],
  head_style : Array[String],
) -> Html {
  let items : Array[Html] = []
  for pair in breadcrumb_segments(path) {
    let (part, target) = pair
    if !items.is_empty() {
      items.push(@rui.breadcrumb_separator())
    }
    // The current directory stays clickable so it can reload the pane; mark it as the current page for assistive tech.
    let attrs = if target == path {
      @html.Attrs::build().aria_current("page")
    } else {
      @html.Attrs::build()
    }
    items.push(
      @rui.breadcrumb_item(
        @rui.button(
          variant=Ghost,
          size=Xs,
          style=[
            UI_FONT_STYLE,
            "font-size: inherit",
            "line-height: inherit",
            "--rui-button-base-fg: var(--rui-muted-foreground)",
          ],
          attrs~,
          on_click=emit(PaneEvent(GotoPath(idx, target))),
          part,
        ),
      ),
    )
  }
  div(class="phead", style=head_style, [
    @rui.breadcrumb(
      aria_label="Directory path",
      style=[
        UI_FONT_STYLE,
        "flex: 1",
        "min-width: 0",
        "--rui-ghost-hover-bg: transparent",
      ],
      @rui.breadcrumb_list(
        style=["font-size: inherit", "line-height: inherit"],
        items,
      ),
    ),
    @rui.button(
      variant=Ghost,
      size=Xs,
      style=[UI_FONT_STYLE, "flex: none"],
      title="Change sort order",
      on_click=emit(SortCycle),
      sort_label,
    ),
  ])
}

///|
fn breadcrumb_segments(path : Path) -> Array[(String, Path)] {
  for current = path, parts = [] {
    let parent = current.dirname()
    guard parent != current else {
      break [(current.to_string(), current), ..parts]
    }
    continue parent, [(current.basename(), current), ..parts]
  }
}

///|
priv struct EntryRow {
  view_id : Int
  directory : String
  row : Int
  entry : Entry
  selected : Bool
  is_cursor : Bool
} derive(Eq)

///|
fn pane_rows(
  pane : Val[Pane],
  filter : Val[String?],
  idx : PaneSide,
  emit : Emit[Msg],
  icons : IconMode,
  openers : @tuzi.OpenRegistry?,
) -> Val[Html] {
  let rows = pane
    .map2(filter, (pane, filter) => {
      let entries = pane.view_data(filter?).entries
      @vector.Vector::from_array(
        entries.mapi((row, entry) => EntryRow::{
          view_id: pane.id,
          directory: pane.path.to_string(),
          row,
          entry,
          selected: pane.selected.contains(entry.name),
          is_cursor: Some(entry.name) == pane.cursor,
        }),
      )
    })
    .assoc_by(
      (name, row) => {
        // Cursor movement only updates the row's appearance, keeping the double-click target mounted.
        let menu = row.switch_by(
          row => entry_context_menu(row, idx, emit, icons, openers),
          by=row => {
            ToJson::to_json(
              (row.view_id, row.directory, row.row, row.entry, row.selected),
            ).stringify()
          },
        )
        menu.map2(row, (menu, row) => {
          (
            name,
            li(
              id="pane-\{idx.index()}-view-\{row.view_id}-row-\{row.row}",
              class="entry-row",
              style=row_style(row.is_cursor, row.selected),
              menu,
            ),
          )
        })
      },
      by=row => row.entry.name,
    )
  rows.view(rows => {
    let children : Map[String, Html] = Map::from_iter(rows.iter())
    ul(class="plist", style=pane_list_style(), children)
  })
}

///|
fn entry_context_menu(
  item : EntryRow,
  idx : PaneSide,
  emit : Emit[Msg],
  icons : IconMode,
  openers : @tuzi.OpenRegistry?,
) -> Val[Html] {
  let { entry, row, selected, .. } = item
  let row_attrs = @html.Attrs::build()
    .on_click(_event => emit(PaneEvent(Click(idx, row))))
    .on_dragstart(_drag => emit(DragStart(idx, entry.name)))
    .on_dragover(allow_drop)
    .on_drop(_drag => emit(Drop(idx)))
    .on_dragend(_drag => emit(DragEnd))
  let children = [
    input(
      input_type=Checkbox,
      checked=selected,
      attrs=@html.Attrs::build().aria_label("Select \{entry.name}"),
      style=[
        "accent-color: var(--rui-primary)", "width: 14px", "height: 14px", "margin: 0",
        "cursor: pointer", "align-self: center",
      ],
      on_change=emit.map(_value => PaneEvent(Select(idx, entry.name))),
    ),
    span(
      style=[
        "color: var(--rui-muted-foreground)", "font-size: var(--tuzi-entry-subtitle-size)",
        "font-variant-numeric: tabular-nums", "text-align: right", "min-width: 2ch",
      ],
      "\{row + 1}",
    ),
    div(
      style=entry_open_area_style(),
      attrs=@html.Attrs::build().on_dblclick(_ev => {
        emit(PaneEvent(DblClick(idx, row)))
      }),
      [
        entry_name_view(entry, @tuzi.entry_color(entry, icons)),
        entry_size_view(entry),
        entry_time_view(entry),
      ],
    ),
  ]
  let id = "pane-\{idx.index()}-view-\{item.view_id}-row-\{row}"
  let trigger_style = [
    "display: grid", "grid-column: 1 / -1", "grid-template-columns: subgrid", "align-items: baseline",
    "min-width: 0", "padding: 4px 10px",
  ]
  @rui.context_menu(id=id + "-open", scope => {
    fragment([
      @rui.context_menu_trigger(
        scope,
        tabindex=-1,
        attrs=row_attrs,
        style=trigger_style,
        children,
      ),
      entry_menu_content(scope, item, idx, openers, emit),
    ])
  })
}

///|
fn PaneViewData::entry_details_view(data : PaneViewData) -> Html {
  let info = data
    .cursor_entry()
    .map_or("", entry => "\{entry.name}  \{format_entry_meta(entry)}")
  div(style=entry_details_style(), info)
}
