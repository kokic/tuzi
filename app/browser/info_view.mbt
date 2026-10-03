///|
fn InfoContext::fields_view(
  context : InfoContext,
  emit : Emit[Msg],
  error? : String = "",
) -> Array[Html] {
  let entry = context.entry
  let path = context.path.to_string()
  [
    InfoField::{ label: "Name", value: entry.name, }.view(),
    ..if !entry.is_symlink {
      [
        InfoField::{ label: "Path", value: path, }.view(
          action=@rui.button(
            variant=Ghost,
            size=Sm,
            style=[UI_FONT_STYLE, "flex-shrink: 0"],
            on_click=@clipboard.copy(
              Text(path),
              copied=emit(Toast("Path copied", Some(path), @rui.ToastSuccess)),
              failed=error => {
                emit(
                  Toast("Clipboard error", Some(error), @rui.ToastDestructive),
                )
              },
            ),
            "Copy",
          ),
        ),
      ]
    },
    ..context.link.map_or([], fields => {
      [
        text_input_field_view(
          id="link-path",
          label="Full link path:",
          value=fields.path,
          error~,
          autofocus=true,
          on_input=emit.map(value => LinkPathInput(value)),
        ),
        text_input_field_view(
          id="link-target",
          label="Full target path:",
          value=fields.target.unwrap_or(""),
          error="",
          on_input=emit.map(value => LinkTargetInput(value)),
        ),
        ..if fields.target is None && error.is_empty() {
          [@rui.field_description("Loading target…")]
        },
      ]
    }),
    InfoField::{
      label: "Type",
      value: if entry.is_symlink {
        if entry.is_dir {
          "Folder link"
        } else {
          "Symbolic link"
        }
      } else if entry.is_dir {
        "Folder"
      } else {
        "File"
      },
    }.view(),
    ..if entry.is_symlink {
      [
        InfoField::{
          label: "Resolved target",
          value: entry.resolved_target.map_or("Unable to resolve", target => {
            target.to_string()
          }),
        }.view(),
      ]
    },
    ..if !entry.is_dir {
      [
        InfoField::{
          label: "Size",
          value: entry.size.map_or("Unknown", size => {
            "\{format_file_size(size)} (\{size} bytes)"
          }),
        }.view(),
      ]
    },
    InfoField::{
      label: "Modified (UTC)",
      value: entry.mtime.map_or("Unknown", time => {
        format_timestamp(time, seconds=true)
      }),
    }.view(),
  ]
}

///|
fn InfoField::view(field : InfoField, action? : Html) -> Html {
  div(
    style=[
      "display: grid", "grid-template-columns: minmax(72px, 96px) minmax(0, 1fr)",
      "gap: 12px", "padding-block: 6px", "min-width: 0", "font-size: 0.8125rem",
    ],
    [
      p(
        style=[
          "margin: 0", "color: var(--rui-muted-foreground)", "line-height: 1.5",
        ],
        field.label,
      ),
      div(
        style=[
          "display: flex", "align-items: flex-start", "gap: 8px", "min-width: 0",
        ],
        [
          p(
            style=[
              "margin: 0", "flex: 1", "min-width: 0", "max-height: 80px", "overflow: auto",
              "line-height: 1.5", "white-space: pre-wrap", "overflow-wrap: anywhere",
              "user-select: text",
            ],
            field.value,
          ),
          ..action.map_or([], action => [action]),
        ],
      ),
    ],
  )
}

///|
fn InfoContext::dialog(
  context : InfoContext,
  additional_content : Array[Html],
  emit : Emit[Msg],
  expanded? : Bool = false,
  error? : String = "",
) -> Html {
  let content = [
    ..if !context.entry.is_dir &&
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
