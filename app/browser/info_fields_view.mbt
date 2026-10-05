///|
fn InfoContext::fields_view(
  context : InfoContext,
  emit : Emit[Msg],
  error? : String = "",
) -> Array[Html] {
  let entry = context.entry
  let path = context.path.to_string()
  let rows = [
    InfoField::{ label: "Name", value: entry.name, }.view(),
    ..if !entry.kind.is_link() {
      [
        InfoField::{ label: "Path", value: path, }.view(
          on_click=@clipboard.copy(
            Text(path),
            copied=emit(Toast("Path copied", Some(path), @rui.ToastSuccess)),
            failed=error => {
              emit(Toast("Clipboard error", Some(error), @rui.ToastDestructive))
            },
          ),
        ),
      ]
    },
    ..context.link.map_or([], fields => {
      [
        info_input_row(
          id="link-path",
          label="Full link path:",
          value=fields.path,
          error~,
          autofocus=true,
          on_input=emit.map(value => LinkPathInput(value)),
        ),
        info_input_row(
          id="link-target",
          label="Full target path:",
          value=fields.target.unwrap_or(""),
          error="",
          loading=fields.target is None && error.is_empty(),
          on_input=emit.map(value => LinkTargetInput(value)),
        ),
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
  [@rui.table(@rui.table_body(rows))]
}

///|
fn InfoField::view(field : InfoField, on_click? : Cmd) -> Html {
  info_row(
    span(field.label),
    on_click.map_or(span(field.value), on_click => {
      span(
        title="Click to copy path",
        attrs=@html.Attrs::build().on_click(_ => on_click),
        field.value,
      )
    }),
  )
}

///|
fn info_row(label : Html, value : Html) -> Html {
  @rui.table_row(style=["border-bottom: none"], [
    @rui.table_head(scope=Row, style=["width: 1%"], label),
    @rui.table_cell(
      style=["white-space: normal", "overflow-wrap: anywhere"],
      value,
    ),
  ])
}

///|
fn info_input_row(
  id~ : String,
  label~ : String,
  value~ : String,
  error~ : String,
  on_input~ : Emit[String],
  autofocus? : Bool = false,
  loading? : Bool = false,
) -> Html {
  let error_id = id + "-error"
  info_row(
    @rui.field_label(
      for_=id,
      style=if error.is_empty() {
        []
      } else {
        ["color: var(--rui-destructive, oklch(0.577 0.245 27.325))"]
      },
      label,
    ),
    @rui.field(
      invalid=!error.is_empty(),
      [
        @rui.input(
          style=[UI_FONT_STYLE],
          id~,
          value~,
          autofocus~,
          on_input~,
          invalid=!error.is_empty(),
          attrs=@html.Attrs::build().aria_describedby(
            if error.is_empty() {
              ""
            } else {
              error_id
            },
          ),
        ),
        ..if !error.is_empty() {
          [@rui.field_error(id=error_id, error)]
        },
        ..if loading {
          [@rui.spinner(label="Loading target…")]
        },
      ],
    ),
  )
}
