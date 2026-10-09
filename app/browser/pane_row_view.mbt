///|
#cfg(target="js")
fn allow_drop(drag : @dom.DragEvent) -> Cmd {
  drag.prevent_default()
  @rabbita.none
}

///|
priv struct EntryRow {
  view_id : Int
  directory : String
  row : Int
  entry : Entry
  selected : Bool
  is_cursor : Bool
  transfer_disabled : Bool
} derive(Eq)

///|
fn pane_rows(
  pane : Val[Pane],
  filter : Val[String?],
  other_path : Val[Path],
  idx : PaneSide,
  emit : Emit[Msg],
  appearance : EntryAppearance,
  openers : @tuzi.OpenRegistry?,
) -> Val[Html] {
  let rows = pane
    .map3(filter, other_path, (pane, filter, other_path) => {
      let entries = pane.view_data(filter?).entries
      @vector.Vector::from_array(
        entries.mapi((row, entry) => EntryRow::{
          view_id: pane.id,
          directory: pane.path.to_string(),
          row,
          entry,
          selected: pane.selected.contains(entry.name),
          is_cursor: Some(entry.name) == pane.cursor,
          transfer_disabled: pane.path == other_path,
        }),
      )
    })
    .assoc_by(
      (name, row) => {
        // Cursor movement only updates the row's appearance, keeping the double-click target mounted.
        let menu = row.switch_by(
          row => entry_context_menu(row, idx, emit, appearance, openers),
          by=row => {
            ToJson::to_json(
              (
                row.view_id,
                row.directory,
                row.row,
                row.entry,
                row.selected,
                row.transfer_disabled,
              ),
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
  appearance : EntryAppearance,
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
        CODE_FONT_STYLE,
        "color: var(--rui-muted-foreground)",
        "font-size: var(--tuzi-entry-title-size)",
        "font-variant-numeric: tabular-nums",
        "text-align: right",
        "min-width: 2ch",
        "margin: 0 4px",
      ],
      "\{row + 1}",
    ),
    div(
      style=entry_open_area_style(),
      attrs=@html.Attrs::build().on_dblclick(_ev => {
        emit(PaneEvent(DblClick(idx, row)))
      }),
      [
        entry.name_view(@presentation.entry_color(entry, appearance)),
        entry_size_view(entry),
        entry_time_view(entry),
      ],
    ),
  ]
  let id = "pane-\{idx.index()}-view-\{item.view_id}-row-\{row}"
  let trigger_style = [
    "display: grid", "grid-column: 1 / -1", "grid-template-columns: subgrid", "align-items: baseline",
    "align-content: center", "min-width: 0", "min-height: var(--tuzi-row-height)",
    "padding: 4px 10px",
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
