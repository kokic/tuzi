///|
fn activity_dialog(jobs : Val[TaskState], emit : Emit[Msg]) -> Val[Html] {
  let rows = jobs
    .map(jobs => {
      @vector.Vector::from_array(
        jobs.items.map(task => ("\{jobs.session}-\{task.id}", task)),
      )
    })
    .assoc((key, task) => {
      task.map(task => (key, activity_item_view(task, emit)))
    })
  rows.view(rows => {
    modal("Activity", emit, size=Wide, [
      if rows.is_empty() {
        @rui.empty(@rui.empty_header(@rui.empty_title("No tasks yet.")))
      } else {
        let children : Map[String, Html] = Map::from_iter(rows.iter())
        @rui.item_group(children)
      },
      dialog_close_footer_view(),
    ])
  })
}

///|
fn activity_item_view(task : Task, emit : Emit[Msg]) -> Html {
  @rui.item(
    variant=ItemOutline,
    attrs=@html.Attrs::build().role("listitem"),
    style=["flex-wrap: nowrap", "align-items: flex-start"],
    [
      task_summary_view(task),
      @rui.item_actions(
        style=["flex-shrink: 0"],
        @rui.button(
          variant=Outline,
          size=Sm,
          style=[UI_FONT_STYLE],
          attrs=@html.Attrs::build().aria_label(
            "View details for task #\{task.id}",
          ),
          on_click=emit(TaskEvent(TaskOpen(task.id))),
          "View details",
        ),
      ),
    ],
  )
}
