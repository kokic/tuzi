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
  let (label, variant) : (String, @rui.BadgeVariant) = match task.status {
    Queued => ("Queued", Secondary)
    Running => ("Running", Secondary)
    Completed(_) => ("Completed", Secondary)
    Failed(_) => ("Failed", Destructive)
  }
  let actions = [
    ..task
    .history_output()
    .map_or([], output => {
      let (label, _) = output
      [
        @rui.button(
          variant=Ghost,
          size=Sm,
          style=[UI_FONT_STYLE],
          on_click=emit(TaskEvent(TaskOutputOpen(task.id))),
          label,
        ),
      ]
    }),
    ..match (task.kind, task.status) {
      (File(Zip(..) | Unzip(..)) | Git(_), Queued | Running | Failed(_)) =>
        [
          @rui.button(
            variant=Ghost,
            size=Sm,
            style=[UI_FONT_STYLE],
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
  ]
  @rui.item(
    variant=ItemOutline,
    style=["flex-wrap: nowrap"],
    [
      @rui.item_media(
        badge(variant~, attrs=@html.Attrs::build().role("status"), label),
      ),
      activity_description_view(task),
      ..if actions.is_empty() {
        []
      } else {
        [@rui.item_actions(actions)]
      },
    ],
  )
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
