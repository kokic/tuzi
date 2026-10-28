///|
fn task_output_view(message : String, label~ : String = "Task output") -> Html {
  @rui.scroll_area(
    orientation=Horizontal,
    attrs=@html.Attrs::build().aria_label(label),
    style=[
      "height: auto", "max-height: 160px", "overflow-y: auto", "overscroll-behavior-y: auto",
    ],
    @html.pre(
      style=[
        CODE_FONT_STYLE,
        "font-size: 0.8125rem",
        "line-height: 1.5",
        "margin: 0",
      ],
      message,
    ),
  )
}
