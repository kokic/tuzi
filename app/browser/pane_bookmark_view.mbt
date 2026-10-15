///|
fn pane_bookmark_menu_view(
  id : String,
  current : Path,
  bookmarks : Array[Path],
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  pane_path_menu_view(
    id,
    current,
    bookmarks.map(path => path.to_string()),
    idx,
    emit,
    label="Bookmarks",
    icon=pane_bookmark_icon(),
    empty_label="No bookmarks yet",
  )
}

///|
fn pane_bookmark_icon() -> Html {
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
          d="m12 3 2.78 5.63L21 9.54l-4.5 4.38 1.06 6.19L12 17.18l-5.56 2.93 1.06-6.19L3 9.54l6.22-.91L12 3Z",
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
