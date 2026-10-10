///|
fn bookmarks_dialog(
  bookmarks : Array[Path],
  side : PaneSide,
  emit : Emit[Msg],
) -> Html {
  let target = match side {
    Left => "left"
    Right => "right"
  }
  modal(
    "Bookmarks",
    emit,
    size=Wide,
    description="Jump to a directory in the \{target} pane.",
    [
      if bookmarks.is_empty() {
        @rui.empty(
          @rui.empty_header([
            @rui.empty_title("No bookmarks yet"),
            @rui.empty_description(
              "Use Command → Bookmarks: Add Current Panel Path to add a directory.",
            ),
          ]),
        )
      } else {
        @rui.scroll_area(
          style=["height: auto", "max-height: 60vh"],
          attrs=@html.Attrs::build().aria_label("Bookmarked directories"),
          @rui.item_group(
            Map::from_iter(
              bookmarks
              .iter()
              .map(path => (path.to_string(), bookmark_item(path, emit))),
            ),
          ),
        )
      },
      dialog_close_footer_view(),
    ],
  )
}

///|
fn bookmark_item(path : Path, emit : Emit[Msg]) -> Html {
  let label = if path == path.dirname() {
    path.to_string()
  } else {
    path.basename()
  }
  @rui.item(variant=ItemOutline, attrs=@html.Attrs::build().role("listitem"), [
    @rui.item_content(style=["min-width: 0"], [
      @rui.item_title(label),
      @rui.item_description(style=["overflow-wrap: anywhere"], path.to_string()),
    ]),
    @rui.item_actions([
      @rui.button(
        variant=Outline,
        size=Sm,
        style=[UI_FONT_STYLE],
        attrs=@html.Attrs::build().aria_label("Jump to \{path}"),
        on_click=emit(BookmarkEvent(Jump(path))),
        "Jump",
      ),
      @rui.button(
        variant=Destructive,
        size=Sm,
        style=[UI_FONT_STYLE],
        attrs=@html.Attrs::build().aria_label("Remove bookmark \{path}"),
        on_click=emit(BookmarkEvent(Remove(path))),
        "Delete",
      ),
    ]),
  ])
}
