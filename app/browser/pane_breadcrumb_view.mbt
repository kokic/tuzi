///|
fn breadcrumbs_view(
  path : Path,
  sort_label : String,
  idx : PaneSide,
  emit : Emit[Msg],
  head_style : Array[String],
  drive_menu~ : Html?,
) -> Html {
  let items : Array[Html] = []
  for pair in breadcrumb_segments(path) {
    let (part, target) = pair
    if items.is_empty() && drive_menu is Some(menu) {
      items.push(@rui.breadcrumb_item(menu))
      continue
    }
    if !items.is_empty() {
      items.push(@rui.breadcrumb_separator())
    }
    // The current directory stays clickable so it can reload the pane; mark it as the current page for assistive tech.
    let attrs = if target == path {
      @html.Attrs::build().aria_current("page")
    } else {
      @html.Attrs::build()
    }
    items.push(
      @rui.breadcrumb_item(
        @rui.button(
          variant=Ghost,
          size=Xs,
          style=[
            UI_FONT_STYLE,
            "font-size: inherit",
            "line-height: inherit",
            "--rui-button-base-fg: var(--rui-muted-foreground)",
          ],
          attrs~,
          on_click=emit(PaneEvent(GotoPath(idx, target))),
          part,
        ),
      ),
    )
  }
  div(class="phead", style=head_style, [
    @rui.breadcrumb(
      aria_label="Directory path",
      style=[
        UI_FONT_STYLE,
        "flex: 1",
        "min-width: 0",
        "--rui-ghost-hover-bg: transparent",
      ],
      @rui.breadcrumb_list(
        style=["font-size: inherit", "line-height: inherit"],
        items,
      ),
    ),
    @rui.button(
      variant=Ghost,
      size=Xs,
      style=[UI_FONT_STYLE, "flex: none"],
      title="Change sort order",
      on_click=emit(SortCycle),
      sort_label,
    ),
  ])
}

///|
fn breadcrumb_segments(path : Path) -> Array[(String, Path)] {
  for current = path, parts = [] {
    let parent = current.dirname()
    guard parent != current else {
      break [(current.to_string(), current), ..parts]
    }
    continue parent, [(current.basename(), current), ..parts]
  }
}
