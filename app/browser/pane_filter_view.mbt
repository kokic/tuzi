///|
fn PaneViewData::entry_details_view(data : PaneViewData) -> Html {
  let info = data
    .cursor_entry()
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
  @rui.input_group(
    style=[
      CODE_FONT_STYLE,
      "width: 320px",
      "max-width: 50%",
      "min-width: 0",
      "flex: none",
      "margin-right: auto",
      "height: 24px",
      "min-height: 0",
      "--rui-control-base-bg: var(--rui-card)",
      "--rui-control-base-border: color-mix(in oklab, var(--rui-muted-foreground) 50%, var(--rui-background))",
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
        title="\{label} (f)",
        on_input=emit.map(text => FilterChanged(idx, text)),
        attrs=@html.Attrs::build()
          .aria_label(label)
          .on_focus(_ => emit(FilterFocus(idx, true)))
          .on_blur(_ => emit(FilterFocus(idx, false))),
      ),
      @rui.input_group_addon(
        align=InputInlineStart,
        for_=filter_input_id(idx, view_id),
        style=["flex: none", "padding: 0 0 0 6px"],
        pane_filter_search_icon(),
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
              attrs=@html.Attrs::build().aria_label("Clear filter"),
              on_click=emit(FilterChanged(idx, "")),
              "×",
            ),
          ),
        ]
      },
    ],
  )
}

///|
fn pane_filter_search_icon() -> Html {
  span(
    attrs=@html.Attrs::build().aria_hidden("true"),
    style=[
      "display: inline-flex", "width: 1rem", "height: 1rem", "flex: none", "pointer-events: none",
    ],
    @svg.svg(
      width=24,
      height=24,
      view_box="0 0 24 24",
      style=["display: block", "width: 100%", "height: 100%"],
      [
        @svg.path(
          d="M21 21l-4.35-4.35M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0",
          fill="none",
          stroke="currentColor",
          stroke_width=2,
          attrs=@svg.Attrs::build()
            .stroke_linecap("round")
            .stroke_linejoin("round"),
        ),
      ],
    ),
  )
}
