///|
fn activity_dialog(jobs : Val[TaskState], emit : Emit[Msg]) -> Val[Html] {
  let rows = jobs
    .map(jobs => {
      @vector.Vector::from_array(
        jobs.items.map(task => ("\{jobs.session}-\{task.id}", task)),
      )
    })
    .assoc((key, task) => {
      // Keep each task's collapsible state when other tasks change or reorder.
      task
      .switch_by(task => activity_item_view(task, emit), by=task => {
        ToJson::to_json(task).stringify()
      })
      .map(row => (key, row))
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
fn activity_item_view(task : Task, emit : Emit[Msg]) -> Val[Html] {
  let (label, message) = match task.status {
    Completed(output) => ("Output", output)
    Failed(error) => ("Error details", error.message)
    Queued | Running => ("", "")
  }
  let output = if message.is_empty() {
    Val::constant([])
  } else {
    @rui.collapsible(
      id="activity-task-\{task.id}-output",
      trigger_style=[UI_FONT_STYLE],
      trigger=label,
      content=@rui.scroll_area(
        orientation=Horizontal,
        attrs=@html.Attrs::build().aria_label(label),
        style=["height: auto"],
        @html.pre(
          style=[
            CODE_FONT_STYLE,
            "margin: 0",
            "white-space: pre",
            "overflow-wrap: normal",
          ],
          message,
        ),
      ),
    ).map(output => [@rui.item_footer(style=["min-width: 0"], output)])
  }
  output.view(output => {
    @rui.item(
      variant=ItemOutline,
      [
        activity_description_view(task),
        @rui.item_footer(
          match task.status {
            Failed(_) =>
              badge(
                variant=Destructive,
                attrs=@html.Attrs::build().role("status"),
                "Failed",
              )
            _ => task_status_view(task.status, task.description)
          },
        ),
        ..output,
        ..match (task.kind, task.status) {
          (File(Zip(..) | Unzip(..)) | Git(_), Queued | Running | Failed(_)) =>
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
  })
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
