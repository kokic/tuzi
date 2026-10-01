///|
/// Render the shared icon data. SVG content comes from trusted code-defined
/// registries, never from file names or other external input.
#warnings("-alert_xss_vulnerable")
fn icon_view(icons : IconTheme, entry : Entry) -> Html {
  match icons {
    None => fragment([])
    Svg(content) => {
      let markup = content.for_entry(entry)
      guard !markup.is_empty() else { return fragment([]) }
      span(
        class="file-icon-svg",
        style=icon_box_style(),
        attrs=@html.Attrs::build().aria_hidden("true").inner_html(markup),
        ([] : Array[Html]),
      )
    }
  }
}
