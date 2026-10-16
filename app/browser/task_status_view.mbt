///|
fn task_indicator(status : TaskStatus) -> Html {
  match status {
    Queued =>
      badge(
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
fn task_status_view(status : TaskStatus, description : String) -> Html {
  match status {
    Queued =>
      badge(
        variant=Secondary,
        attrs=@html.Attrs::build().role("status"),
        "Queued",
      )
    Running => @rui.progress(aria_label=description)
    Completed(_) =>
      badge(
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
