///|
fn InfoContext::fields_view(
  context : InfoContext,
  emit : Emit[Msg],
  error? : String = "",
) -> Array[Html] {
  let entry = context.entry
  let path = context.path.to_string()
  let rows = [
    info_row("Name", entry.name),
    ..if !entry.kind.is_link() {
      [
        info_row(
          "Path",
          span(
            title="Click to copy path",
            attrs=@html.Attrs::build().on_click(_ => {
              @clipboard.copy(
                Text(path),
                copied=emit(Toast("Path copied", Some(path), @rui.ToastSuccess)),
                failed=error => {
                  emit(
                    Toast("Clipboard error", Some(error), @rui.ToastDestructive),
                  )
                },
              )
            }),
            path,
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
    info_row(
      "Type",
      match entry.kind {
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
    ),
    ..if entry.kind is SymbolicLink(target, _) {
      [info_row("Resolved target", target.to_string())]
    },
    ..if entry.kind is UnresolvedLink(error) {
      [info_row("Target unavailable", error.message)]
    },
    ..if entry.marker is Err(error) {
      [info_row("Marker unavailable", error.message)]
    },
    ..if !entry.is_dir() {
      [
        info_row(
          "Size",
          match entry.size {
            Ok(size) =>
              size.map_or("Not applicable", size => {
                "\{format_file_size(size)} (\{size} bytes)"
              })
            Err(error) => error.message
          },
        ),
      ]
    },
    info_row(
      "Modified (UTC)",
      match entry.mtime {
        Ok(time) => format_timestamp(time, seconds=true).to_string()
        Err(error) => error.message
      },
    ),
  ]
  [@rui.table(@rui.table_body(rows))]
}

///|
fn[L : @html.IsChildren, V : @html.IsChildren] info_row(
  label : L,
  value : V,
) -> Html {
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
  let invalid = !error.is_empty()
  let attrs = @html.Attrs::build()
  if invalid {
    ignore(attrs.aria_describedby(error_id))
  }
  info_row(
    @rui.field_label(
      for_=id,
      style=[
        ..if invalid {
          ["color: var(--rui-destructive, oklch(0.577 0.245 27.325))"]
        },
      ],
      label,
    ),
    @rui.field(
      invalid~,
      [
        @rui.input(
          style=[UI_FONT_STYLE],
          id~,
          value~,
          autofocus~,
          on_input~,
          invalid~,
          attrs~,
        ),
        ..if invalid {
          [@rui.field_error(id=error_id, error)]
        },
        ..if loading {
          [@rui.spinner(label="Loading target…")]
        },
      ],
    ),
  )
}
