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
    ..if !entry.kind.is_link() {
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
      value: match entry.kind {
        Regular => "File"
        Directory => "Folder"
        SymbolicLink(_, target_kind) =>
          if target_kind.is_dir() {
            "Folder link"
          } else {
            "Symbolic link"
          }
        UnresolvedLink(_) => "Symbolic link (target unavailable)"
        Socket => "Socket"
        Pipe => "Pipe"
        BlockDevice => "Block device"
        CharDevice => "Character device"
        Unknown => "Unknown"
      },
    }.view(),
    ..if entry.kind is SymbolicLink(target, _) {
      [
        InfoField::{ label: "Resolved target", value: target.to_string(), }.view(),
      ]
    },
    ..if entry.kind is UnresolvedLink(error) {
      [InfoField::{ label: "Target unavailable", value: error, }.view()]
    },
    ..if !entry.is_dir() {
      [
        InfoField::{
          label: "Size",
          value: match entry.size {
            Ok(size) =>
              size.map_or("Not applicable", size => {
                "\{format_file_size(size)} (\{size} bytes)"
              })
            Err(error) => error.message
          },
        }.view(),
      ]
    },
    InfoField::{
      label: "Modified (UTC)",
      value: match entry.mtime {
        Ok(time) => format_timestamp(time, seconds=true).to_string()
        Err(error) => error.message
      },
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
