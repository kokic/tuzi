///|
fn activity_dialog(tasks : Array[Task], emit : Emit[Msg]) -> Html {
  modal("Activity", emit, style=["width: min(640px, calc(100% - 2rem))"], [
    @rui.scroll_area(
      @rui.item_group(
        [
          ..if tasks.is_empty() {
            [@rui.empty(@rui.empty_header(@rui.empty_title("No tasks yet.")))]
          },
          ..tasks.map(task => {
            @rui.item(
              variant=ItemOutline,
              [
                activity_description_view(task),
                @rui.item_footer(
                  task_status_view(task.status, task.description),
                ),
                ..task_details(task).map(output => @rui.item_footer(output)),
                ..match (task.kind, task.status) {
                  (
                    File(Zip(..) | Unzip(..))
                    | Git(_),
                    Queued
                    | Running
                    | Failed(_),
                  ) =>
                    [
                      @rui.item_actions(
                        @rui.button(
                          variant=Ghost,
                          size=Sm,
                          on_click=emit(TaskEvent(TaskOpen(task.id))),
                          if task.status.is_active() {
                            "View progress"
                          } else {
                            "View details"
                          },
                        ),
                      ),
                    ]
                  _ => []
                },
              ],
            )
          }),
        ],
      ),
    ),
    dialog_close_footer_view(),
  ])
}

///|
fn activity_description_view(task : Task) -> Html {
  @rui.item_content(
    match task.kind {
      Git(request) =>
        [
          @rui.item_title("git \{request.operation.name()}"),
          @rui.item_description(request.path.to_string()),
        ]
      File(_) => [@rui.item_title(task.description)]
    },
  )
}
