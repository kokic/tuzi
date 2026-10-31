///|
fn Entry::name_view(entry : Entry, color : String) -> Html {
  match entry.kind {
    Err(_) =>
      entry.name_container(color, [
        truncated_name_view(entry.name),
        @rui.badge(
          variant=Secondary,
          style=["margin-left: 0.5em", "flex: none"],
          "Type unavailable",
        ),
      ])
    Ok(SymbolicLink(target, target_kind)) =>
      entry.symbolic_link_name_view(
        color,
        target.to_string(),
        directory=target_kind.is_dir(),
      )
    Ok(UnresolvedLink(_)) => entry.unresolved_link_name_view(color)
    Ok(Directory) => entry.directory_name_view(color)
    _ => entry.file_name_view(color)
  }
}

///|
fn Entry::file_name_view(entry : Entry, color : String) -> Html {
  entry.name_container(color, [truncated_name_view(entry.name)])
}

///|
fn Entry::directory_name_view(entry : Entry, color : String) -> Html {
  entry.name_container(color, [
    truncated_name_view(entry.name),
    span(style=["flex: none"], "/"),
  ])
}

///|
fn Entry::symbolic_link_name_view(
  entry : Entry,
  color : String,
  target : String,
  directory~ : Bool,
) -> Html {
  entry.name_container(
    color,
    [
      link_name_view(entry.name),
      ..if directory {
        [span(style=["flex: none"], "/")]
      },
      link_arrow_view(),
      span(
        style=["min-width: 3ch", "overflow: hidden", "text-overflow: ellipsis"],
        target,
      ),
    ],
  )
}

///|
fn Entry::unresolved_link_name_view(entry : Entry, color : String) -> Html {
  entry.name_container(color, [
    link_name_view(entry.name),
    span(
      style=["margin-left: 0.5em", "color: var(--rui-muted-foreground)"],
      "Target unavailable",
    ),
  ])
}

///|
fn Entry::name_container(
  entry : Entry,
  color : String,
  children : Array[Html],
) -> Html {
  span(
    style=entry_title_style(entry, color),
    [
      ..children,
      ..if entry.kind is Ok(_) && entry.marker is Err(_) {
        [
          span(
            style=["margin-left: 0.5em", "color: var(--rui-muted-foreground)"],
            "Marker unavailable",
          ),
        ]
      },
    ],
  )
}

///|
fn truncated_name_view(name : String) -> Html {
  span(
    style=[
      "min-width: 0", "overflow: hidden", "text-overflow: ellipsis",
      "text-decoration-line: var(--tuzi-entry-name-decoration, none)",
    ],
    name,
  )
}

///|
fn link_name_view(name : String) -> Html {
  span(
    style=[
      "flex: none", "max-width: 50cqw", "overflow: hidden", "text-overflow: ellipsis",
      "text-decoration-line: var(--tuzi-entry-name-decoration, none)",
    ],
    name,
  )
}

///|
#warnings("-alert_xss_vulnerable")
fn link_arrow_view() -> Html {
  span(
    style=[
      "display: inline-flex", "flex: none", "align-self: center", "width: 1em", "height: 1em",
      "margin: 0 0.5em",
    ],
    attrs=@html.Attrs::build().inner_html(SvgRightArrow),
    @html.nothing,
  )
}

///|
const SvgRightArrow : String =
  #|<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-move-right preview-icon"><path d="M18 8L22 12L18 16"/><path d="M2 12H22"/></svg>
