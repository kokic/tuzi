///|
/// Decorative path icon with a stable one-rem layout box. Defaults to a
/// Lucide-compatible stroke; callers provide the semantic label on the control.
pub fn ui_icon(
  path : String,
  view_box~ : String = "0 0 24 24",
  fill~ : String = "none",
  stroke~ : String = "currentColor",
) -> @html.Html {
  @html.span(
    style=[
      UiBoxSizing,
      "display:inline-flex;width:1rem;height:1rem;flex:none;align-items:center;justify-content:center;pointer-events:none",
    ],
    attrs=@html.Attrs::build().aria_hidden("true"),
    @svg.svg(
      width=16,
      height=16,
      view_box~,
      style=["display:block;width:100%;height:100%"],
      [
        @svg.path(
          d=path,
          fill~,
          stroke~,
          stroke_width=2,
          attrs=@svg.Attrs::build()
            .stroke_linecap("round")
            .stroke_linejoin("round"),
        ),
      ],
    ),
  )
}

///|
/// Render the shared decorative checkmark used by selection indicators.
pub fn ui_check_icon() -> @html.Html {
  ui_icon("M20 6 9 17l-5-5")
}

///|
fn ui_chevron_right_icon() -> @html.Html {
  ui_icon("m9 18 6-6-6-6")
}

///|
fn ui_x_icon() -> @html.Html {
  ui_icon("M18 6 6 18M6 6l12 12")
}

///|
fn ui_chevron_down_icon() -> @html.Html {
  ui_icon("m6 9 6 6 6-6")
}

///|
fn ui_chevron_up_icon() -> @html.Html {
  ui_icon("m18 15-6-6-6 6")
}

///|
fn ui_search_icon() -> @html.Html {
  ui_icon("m21 21-4.3-4.3M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z")
}
