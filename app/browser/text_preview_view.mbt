///|
fn TextPreviewContext::dialog(
  context : TextPreviewContext,
  emit : Emit[Msg],
) -> Html {
  modal(
    context.path.basename(),
    emit,
    size=Reading,
    style=[
      "height: min(780px, calc(100dvh - 32px))", "max-height: calc(100dvh - 32px)",
      "display: flex", "flex-direction: column", "overflow: hidden",
    ],
    [
      @rui.scroll_area(
        orientation=Horizontal,
        attrs=@html.Attrs::build().aria_label("Text preview"),
        style=[
          "height: auto",
          "flex: 1",
          "min-height: 0",
          "overflow-y: auto",
          "padding: 12px",
          "border: 1px solid var(--rui-border)",
          "user-select: text",
          ..if context.content is Loading {
            ["display: flex", "flex-direction: column"]
          },
        ],
        context.content_view(),
      ),
      dialog_close_footer_view(),
    ],
  )
}

///|
fn TextPreviewContext::content_view(context : TextPreviewContext) -> Html {
  match context.content {
    Loading => centered_loading_view("Loading text…")
    Loaded(Err(error)) =>
      @rui.alert(variant=Destructive, [
        @rui.alert_title("Unable to load text"),
        @rui.alert_description(error),
      ])
    Loaded(Ok(source)) =>
      @html.pre(
        style=[
          CODE_FONT_STYLE,
          "margin: 0",
          "white-space: pre",
          "overflow-wrap: normal",
          "font-size: 0.8125rem",
          "line-height: 1.6",
        ],
        source,
      )
  }
}
