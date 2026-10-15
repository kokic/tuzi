///|
fn pane_history_menu_view(
  id : String,
  current : Path,
  history : Set[String],
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  pane_path_menu_view(
    id,
    current,
    history.to_array().rev_iter().to_array(),
    idx,
    emit,
    label="Path history",
    icon=pane_history_icon(),
  )
}

///|
fn pane_history_icon() -> Html {
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
          d="M3 12a9 9 0 1 0 2.64-6.36L3 8m0-5v5h5m4-1v5l3 2",
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
