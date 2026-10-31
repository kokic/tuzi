///|
fn Pane::entry_details_view(pane : Pane) -> Html {
  let info = pane
    .cursor_index()
    .map(index => pane.visible_entries[index])
    .map_or("", entry => "\{entry.name}  \{format_entry_meta(entry)}")
  div(style=entry_details_style(), [
    span(style=["flex: 1", ..status_text_style()], title=info, info),
  ])
}

///|
fn pane_filter_view(
  idx : PaneSide,
  view_id : Int32,
  filter : String,
  emit : Emit[Msg],
) -> Html {
  let label = match idx {
    Left => "Filter left pane"
    Right => "Filter right pane"
  }
  @rui.input(
    style=[
      @presentation.CONTENT_FONT_STYLE,
      "width: 240px",
      "max-width: 50%",
      "min-width: 0",
      "flex: none",
      "margin-left: 4px",
      "margin-right: auto",
      "height: 24px",
      "min-height: 0",
      "padding: 0 6px",
      "line-height: inherit",
      "border: 0",
      "background: transparent",
      "box-shadow: none",
      "outline: none",
    ],
    id=filter_input_id(idx, view_id),
    value=filter,
    placeholder="Search",
    title="\{label} (f)",
    on_input=emit.map(text => FilterChanged(idx, text)),
    attrs=@html.Attrs::build()
      .aria_label(label)
      .on_focus(_ => emit(FilterFocus(idx, true)))
      .on_blur(_ => emit(FilterFocus(idx, false))),
  )
}
