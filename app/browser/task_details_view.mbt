///|
fn task_details_dialog(tasks : Array[Task], id : Int, emit : Emit[Msg]) -> Html {
  guard tasks.iter().find_first(task => task.id == id) is Some(task) else {
    modal("Task details", emit, [
      @rui.empty(
        @rui.empty_header([
          @rui.empty_title("Task unavailable"),
          @rui.empty_description(
            "This task is not available in this server session.",
          ),
        ]),
      ),
      dialog_close_footer_view(),
    ])
  }
  let active = task.status.is_active()
  modal(
    "Task details",
    emit,
    [
      @rui.item([
        @rui.item_content([
          @rui.item_title(task.description),
          @rui.item_description("Task #\{task.id}"),
        ]),
        @rui.item_footer(task_status_view(task.status, task.description)),
      ]),
      ..task_details(task),
      ..if active {
        [
          @rui.dialog_description(
            "This operation continues on the server when this window is hidden or the page is refreshed.",
          ),
        ]
      },
      dialog_close_footer_view(label=if active { "Hide" } else { "Close" }),
    ],
  )
}
