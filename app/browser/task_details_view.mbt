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
