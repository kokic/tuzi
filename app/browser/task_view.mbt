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
      "scrollbar-width: auto", "scrollbar-color: var(--rui-muted-foreground) var(--rui-muted)",
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
  @rui.alert(style=[UI_FONT_STYLE], variant=Destructive, [
    @rui.alert_title(title),
    @rui.alert_description(task_output_view(message)),
  ])
}

///|
fn activity_dialog(tasks : Array[Task], emit : Emit[Msg]) -> Html {
  modal(
    "Activity",
    emit,
    style=[
      "width: min(560px, 100%)", "display: grid", "grid-template-rows: auto minmax(0, 1fr) auto",
      "min-height: min(320px, 80dvh)", "max-height: calc(100dvh - 32px)", "overflow: hidden",
    ],
    [
      div(
        style=[
          "min-width: 0", "min-height: 0", "max-height: 60vh", "overflow-y: auto",
          "display: grid", "grid-template-columns: minmax(0, 1fr)", "gap: 12px",
          "align-content: start",
        ],
        [
          ..if tasks.is_empty() {
            [
              div(
                style=[
                  "min-height: min(200px, 40dvh)", "display: grid", "place-items: center",
                  "text-align: center",
                ],
                [@rui.field_description("No tasks yet.")],
              ),
            ]
          },
          ..tasks.map(task => {
            div(
              style=[
                "display: grid", "gap: 10px", "padding: 14px", "border: 1px solid var(--rui-border)",
                "border-radius: var(--rui-radius)", "min-width: 0", "grid-template-columns: minmax(0, 1fr)",
              ],
              [
                match task.status {
                  Failed(_) =>
                    @rui.badge(
                      style=[UI_FONT_STYLE],
                      variant=Destructive,
                      attrs=@html.Attrs::build().role("status"),
                      "Failed",
                    )
                  _ => task_status_view(task.status, task.description)
                },
                activity_description_view(task),
                ..match task.status {
                  Failed(error) =>
                    [
                      div(
                        style=["min-width: 0", "color: var(--rui-destructive)"],
                        attrs=@html.Attrs::build().role("alert"),
                        task_output_view(error.message),
                      ),
                    ]
                  _ => task_details(task)
                },
                ..match (task.kind, task.status) {
                  (
                    File(Zip(..) | Unzip(..))
                    | Git(_),
                    Queued
                    | Running
                    | Failed(_),
                  ) =>
                    [
                      @rui.button(
                        variant=Ghost,
                        size=Sm,
                        style=[UI_FONT_STYLE, "justify-self: start"],
                        on_click=emit(TaskEvent(TaskOpen(task.id))),
                        if task.status.is_active() {
                          "View progress"
                        } else {
                          "View details"
                        },
                      ),
                    ]
                  _ => []
                },
              ],
            )
          }),
        ],
      ),
      dialog_close_footer_view(),
    ],
  )
}

///|
fn activity_description_view(task : Task) -> Html {
  let title_style = [
    "margin: 0", "font-size: 0.8125rem", "font-weight: 500", "line-height: 1.5",
    "overflow-wrap: anywhere",
  ]
  match task.kind {
    Git(request) =>
      div(style=["display: grid", "gap: 4px", "min-width: 0"], [
        p(
          style=[..title_style, CODE_FONT_STYLE],
          "git \{request.operation.name()}",
        ),
        @rui.field_description(
          style=[
            "margin: 0", "font-size: 0.75rem", "line-height: 1.5", "overflow-wrap: anywhere",
          ],
          request.path.to_string(),
        ),
      ])
    File(_) => p(style=title_style, task.description)
  }
}

///|
fn progress_dialog(batch : ProgressBatch, emit : Emit[Msg]) -> Html {
  let needs_attention = batch.error is Some(_) ||
    batch.items.any(item => {
      item.state is (Rejected(_) | Tracking(_, Some(Failed(_))))
    })
  let rows = batch.items.map(item => {
    let description = item.operation.description()
    div(
      style=[
        "display: grid", "gap: 10px", "padding: 14px", "border: 1px solid var(--rui-border)",
        "border-radius: var(--rui-radius)", "min-width: 0",
      ],
      [
        ..if batch.error is None {
          [progress_state_view(item.state, description)]
        },
        p(
          style=[
            "margin: 0", "font-weight: 600", "line-height: 1.5", "overflow-wrap: anywhere",
          ],
          description,
        ),
      ],
    )
  })
  modal(
    "In progress",
    emit,
    style=["width: min(520px, 100%)"],
    [
      ..batch.error.map_or([], error => {
        let title = match error {
          Rejected(_) => "Submission rejected"
          _ => "Submission not confirmed"
        }
        [task_error_view(title, error.submission_message())]
      }),
      div(
        style=[
          "display: grid", "gap: 12px", "min-height: 0", "max-height: 60vh", "overflow-y: auto",
          "align-content: start",
        ],
        rows,
      ),
      dialog_close_footer_view(
        label=if needs_attention { "Close" } else { "Hide" },
      ),
    ],
  )
}

///|
fn progress_state_view(state : ProgressState, description : String) -> Html {
  let message = match state {
    Rejected(error) =>
      return task_error_view("Submission rejected", error.message)
    Tracking(_, Some(status)) => return task_status_view(status, description)
    Submitting => "Submitting…"
    Tracking(_, None) => "Waiting for task status…"
  }
  @rui.field_description(style=["margin: 0", "line-height: 1.5"], message)
}

///|
fn task_details_dialog(tasks : Array[Task], id : Int, emit : Emit[Msg]) -> Html {
  guard tasks.iter().find_first(task => task.id == id) is Some(task) else {
    return modal("Task details", emit, [
      @rui.field_description(
        "This task is not available in this server session.",
      ),
      dialog_close_footer_view(),
    ])
  }
  let name = task.description
  let active = task.status.is_active()
  let close_label = if active { "Hide" } else { "Close" }
  modal("Task details", emit, style=["width: min(480px, 100%)"], [
    div(
      style=["display: grid", "gap: 16px", "min-width: 0"],
      [
        task_status_view(task.status, task.description),
        div(style=["display: grid", "gap: 6px", "min-width: 0"], [
          p(
            style=["margin: 0", "font-weight: 600", "overflow-wrap: anywhere"],
            name,
          ),
          @rui.field_description(
            style=["margin: 0", "line-height: 1.5", "overflow-wrap: anywhere"],
            "Task #\{task.id}",
          ),
        ]),
        ..task_details(task),
        ..if active {
          [
            @rui.field_description(
              style=["margin: 0", "line-height: 1.5"],
              "This operation continues on the server when this window is hidden or the page is refreshed.",
            ),
          ]
        },
      ],
    ),
    dialog_close_footer_view(label=close_label),
  ])
}
