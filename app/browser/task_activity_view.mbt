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
