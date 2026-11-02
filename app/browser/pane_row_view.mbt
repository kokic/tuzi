///|
priv struct EntryRow {
  view_id : Int32
  directory : Path
  row : Int32
  entry : Entry
  selected : Bool
  is_cursor : Bool
  transfer_disabled : Bool
} derive(Eq)

///|
fn pane_rows(
  pane : Val[Pane],
  other_path : Val[Path],
  idx : PaneSide,
  emit : Emit[Msg],
  appearance : EntryAppearance,
  openers : @tuzi.OpenRegistry?,
) -> Val[Html] {
  let rows = pane
    .map2(other_path, (pane, other_path) => {
      let entries = pane.visible_entries
      @vector.Vector::from_array(
        entries.mapi((row, entry) => EntryRow::{
          view_id: pane.id,
          directory: pane.path,
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
              class=if row.is_cursor {
                "entry-row is-cursor"
              } else {
                "entry-row"
              },
              menu,
            ),
          )
        })
      },
      by=row => row.entry.name,
    )
  rows.view(rows => {
    let children : Map[String, Html] = Map::from_iter(rows.iter())
    ul(class="plist", children)
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
  let entry_color = @presentation.entry_color(entry, appearance)
  let row_attrs = @html.Attrs::build().on_click(_event => {
    emit(PaneEvent(Click(idx, row)))
  })
  let children = [
    span(
      class="entry-meta",
      style=["text-align: right", "min-width: 2ch", "margin: 0 4px"],
      "\{row + 1}",
    ),
    div(
      class="entry-open-area",
      attrs=@html.Attrs::build().on_dblclick(_ev => {
        emit(PaneEvent(DblClick(idx, row)))
      }),
      [
        div(
          style=[
            "grid-column: 1",
            "position: relative",
            "min-width: 0",
            "padding-left: \{if selected { "32px" } else { "0px" }}",
            "transition: padding-left 160ms ease",
            "--tuzi-entry-name-decoration: \{if selected { "underline" } else { "none" }}",
          ],
          [
            ..if selected {
              [
                span(
                  attrs=@html.Attrs::build().aria_hidden("true"),
                  style=[
                    "position: absolute", "left: 0", "width: 32px", "text-align: center",
                    "color: var(--rui-foreground)", "pointer-events: none", "user-select: none",
                  ],
                  "✓",
                ),
              ]
            } else {
              []
            },
            entry.name_view(entry_color),
          ],
        ),
        entry_size_view(entry),
        entry_time_view(entry),
      ],
    ),
  ]
  let id = "pane-\{idx.index()}-view-\{item.view_id}-row-\{row}"
  let trigger_style = [
    "display: grid", "grid-column: 1 / -1", "grid-template-columns: subgrid", "align-items: baseline",
    "align-content: center", "min-width: 0", "min-height: var(--tuzi-row-height)",
    "padding: 4px 10px", "outline: none",
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
      entry_menu_content(
        scope,
        {
          pane: idx,
          path: item.directory.join(Path("./\{entry.name}")),
          entry,
        },
        openers,
        emit,
        emit.map(action => EntryAction(idx, item.view_id, entry.name, action)),
        transfer_disabled=item.transfer_disabled,
      ),
    ])
  })
}
