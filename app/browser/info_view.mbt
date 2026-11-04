///|
fn InfoContext::dialog(
  context : InfoContext,
  additional_content : Array[Html],
  emit : Emit[Msg],
  tall~ : Bool = false,
  error~ : String = "",
) -> Html {
  let content = [
    ..if context.entry.kind is Ok(kind) &&
      !kind.is_dir() &&
      @tuzi.image_content_type(context.entry.name) is Some(_) {
      [context.image_view()]
    },
    ..context.font_preview.map_or([], preview => {
      [context.font_preview_view(preview, emit)]
    }),
    ..context.fields_view(emit, error~),
    ..additional_content,
  ]
  modal(
    "Information",
    emit,
    size=Wide(tall~),
    style=[
      "max-height: calc(100dvh - 32px)", "display: flex", "flex-direction: column",
      "overflow: hidden",
    ],
    [
      dialog_body(content),
      if context.link is Some(_) {
        @rui.dialog_footer(style=["flex-shrink: 0"], [
          dialog_close_button("Close"),
          @rui.button(
            style=[@presentation.UI_FONT_STYLE],
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
        ],
      ),
    ],
  )
}
