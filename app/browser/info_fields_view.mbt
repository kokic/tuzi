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
          [@rui.spinner(label="Loading target…")]
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
      [InfoField::{ label: "Target unavailable", value: error.message, }.view()]
    },
    ..if entry.marker is Err(error) {
      [InfoField::{ label: "Marker unavailable", value: error.message, }.view()]
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
  @rui.item(
    size=ItemSm,
    [
      @rui.item_content([@rui.item_title(field.label), p(field.value)]),
      ..action.map_or([], action => [@rui.item_actions(action)]),
    ],
  )
}
