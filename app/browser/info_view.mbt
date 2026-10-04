///|
fn InfoContext::dialog(
  context : InfoContext,
  additional_content : Array[Html],
  emit : Emit[Msg],
  expanded? : Bool = false,
  error? : String = "",
) -> Html {
  let content = [
    ..if !context.entry.is_dir() &&
      @tuzi.image_content_type(context.entry.name) is Some(_) {
      [context.image_view()]
    },
    ..context.fields_view(emit, error~),
    ..additional_content,
  ]
  modal(
    "Information",
    emit,
    style=[
      "width: 640px",
      "max-width: 100%",
      "max-height: calc(100dvh - 32px)",
      "display: flex",
      "flex-direction: column",
      "overflow: hidden",
      ..if expanded {
        ["height: min(720px, calc(100dvh - 32px))"]
      },
    ],
    [
      div(
        // Keep control shadows and focus outlines inside the scroll viewport.
        style=[
          "flex: 1 1 auto", "min-height: 0", "min-width: 0", "overflow-y: auto",
          "overflow-x: hidden", "scrollbar-gutter: stable", "padding-inline: 4px",
        ],
        content,
      ),
      if context.link is Some(_) {
        @rui.dialog_footer([
          dialog_close_button("Close"),
          @rui.button(
            style=[UI_FONT_STYLE],
            on_click=emit(DialogSubmit),
            "Save",
          ),
        ])
      } else {
        dialog_close_footer_view()
      },
    ],
  )
}

///|
fn InfoContext::image_view(context : InfoContext) -> Html {
  let path : String = @js.globalThis.apply_with_string("encodeURIComponent", [
    context.path.to_string(),
  ])
  div(
    style=[
      "display: flex", "justify-content: center", "padding: 12px", "margin-bottom: 12px",
      "border: 1px solid var(--rui-border)", "border-radius: var(--rui-radius)",
      "background: var(--rui-muted)",
    ],
    [
      @html.img(
        src="/api/image?path=\{path}",
        alt="Image preview unavailable: \{context.entry.name}",
        title=context.entry.name,
        decoding="async",
        style=[
          "display: block", "max-width: 100%", "max-height: 45dvh", "object-fit: contain",
          "border-radius: var(--rui-radius)",
        ],
      ),
    ],
  )
}
