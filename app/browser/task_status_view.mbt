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

///|
fn task_status_badge(status : TaskStatus) -> Html {
  let (label, variant) : (String, @rui.BadgeVariant) = match status {
    Queued => ("Queued", Secondary)
    Running => ("Running", Secondary)
    Completed(_) => ("Completed", Secondary)
    Failed(_) => ("Failed", Destructive)
  }
  badge(variant~, attrs=@html.Attrs::build().role("status"), label)
}

///|
fn task_summary_view(task : Task, full_path~ : Bool = false) -> Html {
  @rui.item_content(
    match task.kind {
      Git(request) =>
        [
          @rui.item_title(style=["flex-wrap: wrap"], [
            span("git \{request.operation.name()}"),
            task_status_badge(task.status),
          ]),
          @rui.item_description(
            title=request.path.to_string(),
            style=if full_path {
              ["-webkit-line-clamp: unset", "text-wrap: wrap"]
            } else {
              []
            },
            request.path.to_string(),
          ),
        ]
      File(_) =>
        [
          @rui.item_title(style=["flex-wrap: wrap"], [
            span(task.description),
            task_status_badge(task.status),
          ]),
        ]
    },
  )
}
