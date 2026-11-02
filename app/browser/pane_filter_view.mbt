///|
fn Model::entry_details_view(model: Model, pane : Pane) -> Html {
  let info = pane
    .cursor_index()
    .map(index => pane.visible_entries[index])
    .map_or("", entry => "\{entry.name}  \{format_entry_meta(entry)}")
  let left = model.panes.0.current.visible_entries.length()
  let right = model.panes.1.current.visible_entries.length()
  div(class="entry-details", [
    div(
      style=[
        "display: flex", "align-items: center", "gap: 6px", "color: var(--rui-muted-foreground)",
        "white-space: nowrap",
      ],
      [
        span(
          class=if model.active == Left {
            "tuzi-count is-active"
          } else {
            "tuzi-count"
          },
          "\{left}",
        ),
        span("·"),
        span(
          class=if model.active == Right {
            "tuzi-count is-active"
          } else {
            "tuzi-count"
          },
          "\{right}",
        ),
        // span("items"),
      ],
    ),
    span(class="tuzi-status-text", style=["flex: 1"], title=info, info),
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
