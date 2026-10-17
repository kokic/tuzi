///|
fn task_details_dialog(
  tasks : Array[Task],
  id : Int32,
  emit : Emit[Msg],
) -> Html {
  guard tasks.iter().find_first(task => task.id == id) is Some(task) else {
    modal("Task details", emit, size=Wide, [
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
  let output = task.history_output()
  let description = if active {
    Some(
      "This operation continues on the server when this window is hidden or the page is refreshed.",
    )
  } else {
    None
  }
  modal(
    "Task details",
    emit,
    size=Wide,
    description?,
    style=[
      "max-height: calc(100dvh - 32px)", "display: flex", "flex-direction: column",
      "overflow: hidden",
    ],
    [
      @rui.item(style=["flex-shrink: 0"], [
        task_summary_view(task, full_path=true),
        @rui.item_footer(@rui.item_description("Task #\{task.id}")),
      ]),
      ..if task.status is Running {
        [@rui.progress(aria_label=task.description)]
      } else {
        []
      },
      ..output.map_or([], output => {
        let (label, message) = output
        [
          @rui.item_title(style=["flex-shrink: 0"], label),
          @rui.scroll_area(
            orientation=Horizontal,
            attrs=@html.Attrs::build().aria_label(label),
            style=[
              "height: auto", "max-height: 50dvh", "min-height: 0", "overflow-y: auto",
            ],
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
        ]
      }),
      dialog_close_footer_view(label=if active { "Hide" } else { "Close" }, actions=[
        @rui.button(
          variant=Outline,
          style=[UI_FONT_STYLE],
          on_click=emit(ActivityOpen),
          "Back to Activity",
        ),
      ]),
    ],
  )
}
