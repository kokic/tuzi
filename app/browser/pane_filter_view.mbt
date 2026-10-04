///|
fn PaneViewData::entry_details_view(
  data : PaneViewData,
  idx : PaneSide,
  view_id : Int,
  filter : String,
  emit : Emit[Msg],
) -> Html {
  let info = data
    .cursor_entry()
    .map_or("", entry => "\{entry.name}  \{format_entry_meta(entry)}")
  div(style=entry_details_style(), [
    span(style=["flex: 1", ..status_text_style()], title=info, info),
    pane_filter_view(idx, view_id, filter, emit),
  ])
}

///|
fn pane_filter_view(
  idx : PaneSide,
  view_id : Int,
  filter : String,
  emit : Emit[Msg],
) -> Html {
  let label = match idx {
    Left => "Filter left pane"
    Right => "Filter right pane"
  }
  @rui.input_group(
    style=[
      CODE_FONT_STYLE,
      "width: 320px",
      "max-width: 50%",
      "min-width: 0",
      "flex: none",
      "height: 24px",
      "min-height: 0",
    ],
    [
      @rui.input_group_input(
        style=[
          CODE_FONT_STYLE,
          "font-size: inherit",
          "line-height: inherit",
          "padding: 0 6px",
        ],
        id=filter_input_id(idx, view_id),
        value=filter,
        placeholder="Filter files…",
        title="\{label} (f)",
        on_input=emit.map(text => FilterChanged(idx, text)),
        attrs=@html.Attrs::build()
          .aria_label(label)
          .on_focus(_ => emit(FilterFocus(idx, true)))
          .on_blur(_ => emit(FilterFocus(idx, false))),
      ),
      ..if !filter.is_empty() {
        [
          @rui.input_group_addon(
            align=InputInlineEnd,
            style=["padding: 0 2px", "font-size: inherit"],
            @rui.input_group_button(
              style=[
                CODE_FONT_STYLE,
                "height: 20px",
                "font-size: inherit",
                "line-height: inherit",
              ],
              title="Clear filter",
              on_click=emit(FilterChanged(idx, "")),
              "×",
            ),
          ),
        ]
      },
    ],
  )
}
