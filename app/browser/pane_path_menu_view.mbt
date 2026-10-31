///|
fn pane_path_menu_view(
  id : String,
  current : Path,
  paths : Array[String],
  idx : PaneSide,
  emit : Emit[Msg],
  label~ : String,
  icon~ : Html,
  empty_label? : String,
) -> Val[Html] {
  let current = current.to_string()
  @rui.dropdown_menu(id~, scope => {
    fragment([
      @rui.dropdown_menu_trigger(
        scope,
        variant=Ghost,
        size=Xs,
        aria_label=label,
        title=label,
        style=[UI_FONT_STYLE, "flex: none", "width: 24px", "padding: 0"],
        icon,
      ),
      @rui.dropdown_menu_content(
        scope,
        align=Start,
        aria_label=label,
        style=[
          ..popover_style, "max-width: min(32rem, calc(100vw - 1rem))", "max-height: min(16rem, var(--rui-menu-available-height, calc(100vh - 1rem)))",
        ],
        [
          @rui.dropdown_menu_label(style=["flex: none"], label),
          ..if paths.is_empty() {
            empty_label.map_or([], text => {
              [@rui.dropdown_menu_item(scope, disabled=true, text)]
            })
          } else {
            paths.map(path => {
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
          },
        ],
      ),
    ])
  })
}
