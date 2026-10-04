///|
fn task_indicator(status : TaskStatus) -> Html {
  match status {
    Queued =>
      @rui.badge(
        style=[UI_FONT_STYLE, "flex-shrink: 0"],
        variant=Secondary,
        attrs=@html.Attrs::build().aria_label("Queued"),
        "Queued",
      )
    Running => @rui.spinner(label="Running", style=["flex-shrink: 0"])
    Completed(_) =>
      span(attrs=@html.Attrs::build().aria_label("Completed"), "✓")
    Failed(_) => span(attrs=@html.Attrs::build().aria_label("Failed"), "✕")
  }
}

///|
/// Keep logs inside a bounded viewport so long lines cannot widen the card.
fn task_output_view(message : String) -> Html {
  @rui.scroll_area(
    orientation=Horizontal,
    attrs=@html.Attrs::build().aria_label("Task output"),
    style=[
      "min-width: 0", "max-width: 100%", "height: auto", "max-height: 160px", "overflow-y: auto",
      "border-radius: var(--rui-radius)", "background: var(--rui-muted)",
    ],
    @html.pre(
      style=[
        "margin: 0",
        "padding: 10px",
        "box-sizing: border-box",
        "width: max-content",
        "min-width: 100%",
        "white-space: pre",
        "overflow-wrap: normal",
        CODE_FONT_STYLE,
        "font-size: 0.75rem",
        "line-height: 1.6",
      ],
      message,
    ),
  )
}

///|
fn task_details(task : Task) -> Array[Html] {
  match task.status {
    Queued | Running => []
    Completed(output) =>
      if output.is_empty() {
        []
      } else {
        [task_output_view(output)]
      }
    Failed(_) => []
  }
}

///|
fn task_status_view(status : TaskStatus, description : String) -> Html {
  match status {
    Queued =>
      @rui.badge(
        style=[UI_FONT_STYLE],
        variant=Secondary,
        attrs=@html.Attrs::build().role("status"),
        "Queued",
      )
    Running => @rui.progress(style=[UI_FONT_STYLE], aria_label=description)
    Completed(_) =>
      @rui.badge(
        style=[UI_FONT_STYLE],
        variant=Secondary,
        attrs=@html.Attrs::build().role("status"),
        "Completed",
      )
    Failed(error) => task_error_view("Failed", error.message)
  }
}

///|
fn task_error_view(title : String, message : String) -> Html {
  @rui.alert(variant=Destructive, [
    @rui.alert_title(title),
    @rui.alert_description(task_output_view(message)),
  ])
}
