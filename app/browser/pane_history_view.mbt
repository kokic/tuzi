///|
fn pane_history_menu_view(
  id : String,
  current : Path,
  history : Set[String],
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  let paths = history.to_array()
  let current = current.to_string()
  @rui.dropdown_menu(id~, scope => {
    fragment([
      @rui.dropdown_menu_trigger(
        scope,
        variant=Ghost,
        size=Xs,
        aria_label="Path history",
        title="Path history",
        style=[UI_FONT_STYLE, "flex: none", "width: 24px", "padding: 0"],
        pane_history_icon(),
      ),
      @rui.dropdown_menu_content(
        scope,
        align=Start,
        aria_label="Path history",
        style=[
          UI_FONT_STYLE,
          "max-width: min(32rem, calc(100vw - 1rem))",
          "max-height: min(16rem, var(--rui-menu-available-height, calc(100vh - 1rem)))",
        ],
        [
          @rui.dropdown_menu_label(style=["flex: none"], "Path history"),
          ..paths
          .rev_iter()
          .map(path => {
            let is_current = path == current
            @rui.dropdown_menu_item(
              scope,
              disabled=is_current,
              title=path,
              aria_label=if is_current {
                "\{path} (current directory)"
              } else {
                path
              },
              style=["flex: none"],
              on_select=emit(PaneEvent(GotoPath(idx, Path(path)))),
              [
                span(
                  attrs=@html.Attrs::build().aria_hidden("true"),
                  style=["width: 1rem", "flex: none", "text-align: center"],
                  if is_current {
                    "✓"
                  } else {
                    ""
                  },
                ),
                span(style=status_text_style(), path),
              ],
            )
          })
          .to_array(),
        ],
      ),
    ])
  })
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
