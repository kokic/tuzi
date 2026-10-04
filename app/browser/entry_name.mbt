///|
/// Keep the directory marker visible when the filename is truncated.
#warnings("-alert_xss_vulnerable")
fn entry_name_view(entry : Entry, color : String) -> Html {
  span(
    style=entry_title_style(entry, color),
    title=if entry.is_dir() { entry.name + "/" } else { entry.name },
    [
      span(
        style=if entry.kind.is_link() {
          ["flex: none"]
        } else {
          ["min-width: 0", "overflow: hidden", "text-overflow: ellipsis"]
        },
        entry.name,
      ),
      ..if entry.is_dir() {
        [span(style=["flex: none"], "/")]
      } else {
        []
      },
      ..if entry.kind is SymbolicLink(target, _) {
        let target = target.to_string()
        [
          span(
            style=[
              "display: inline-flex", "flex: none", "align-self: center", "width: 1em",
              "height: 1em", "margin: 0 0.5em",
            ],
            // Only the static SVG constant is inserted as HTML.
            attrs=@html.Attrs::build().inner_html(SvgRightArrow),
            @html.nothing,
          ),
          span(
            style=[
              "min-width: 3ch", "overflow: hidden", "text-overflow: ellipsis",
            ],
            title=target,
            target,
          ),
        ]
      },
      ..if entry.kind is UnresolvedLink(error) {
        [
          span(
            style=["margin-left: 0.5em", "color: var(--rui-muted-foreground)"],
            title=error,
            "Target unavailable",
          ),
        ]
      },
    ],
  )
}

///|
const SvgRightArrow : String =
  #|<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-move-right preview-icon"><path d="M18 8L22 12L18 16"/><path d="M2 12H22"/></svg>
