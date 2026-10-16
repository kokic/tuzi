///|
fn task_output_dialog(
  tasks : Array[Task],
  id : Int32,
  emit : Emit[Msg],
) -> Html {
  guard tasks.iter().find_first(task => task.id == id) is Some(task) &&
    task.history_output() is Some((label, message)) else {
    return modal("Task output", emit, size=Wide, [
      @rui.empty(@rui.empty_header(@rui.empty_title("Task output unavailable"))),
      dialog_close_footer_view(),
    ])
  }
  modal(
    label,
    emit,
    size=Reading,
    description="Task #\{task.id}: \{task.description}",
    style=[
      "height: min(720px, calc(100dvh - 32px))", "max-height: calc(100dvh - 32px)",
      "display: flex", "flex-direction: column", "overflow: hidden",
    ],
    [
      // A single viewport owns both axes; long lines retain horizontal scrolling.
      @rui.scroll_area(
        orientation=Horizontal,
        attrs=@html.Attrs::build().aria_label(label),
        style=["height: auto", "flex: 1", "min-height: 0", "overflow-y: auto"],
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
      dialog_close_footer_view(actions=[
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

///|
fn task_output_view(message : String, label~ : String = "Task output") -> Html {
  @rui.scroll_area(
    orientation=Horizontal,
    attrs=@html.Attrs::build().aria_label(label),
    style=[
      "height: auto", "max-height: 160px", "overflow-y: auto", "overscroll-behavior-y: auto",
    ],
    @html.pre(style=[CODE_FONT_STYLE], message),
  )
}
