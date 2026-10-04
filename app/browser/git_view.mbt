///|
fn git_info_dialog(
  context : GitContext,
  jobs : TaskState,
  emit : Emit[Msg],
  error? : String = "",
) -> Html {
  let content = git_info_content(
    context,
    latest_git_task(jobs.items, context.entry.path),
    jobs.submitting,
    emit,
  )
  context.entry.dialog(content, emit, expanded=true, error~)
}

///|
fn git_info_content(
  context : GitContext,
  task : Task?,
  submitting : Bool,
  emit : Emit[Msg],
) -> Array[Html] {
  let panel = context.panel
  let busy = submitting || task.map_or(false, task => task.status.is_active())
  let disabled = panel.loading || busy
  let current = panel.info.map_or("", info => {
    guard info.available else { return "" }
    if info.current.is_empty() {
      "Detached HEAD"
    } else {
      info.current
    }
  })
  [
    div(
      style=[
        "min-width: 0", "margin-top: 16px", "padding-top: 16px", "border-top: 1px solid var(--rui-border)",
        "display: grid", "gap: 12px",
      ],
      [
        div(
          style=[
            "display: flex", "align-items: center", "gap: 12px", "min-width: 0",
          ],
          [
            p(style=["margin: 0", "font-weight: 600", "flex-shrink: 0"], "Git"),
            span(
              style=[
                ..status_text_style(),
                "flex: 1",
                "font-size: 0.8125rem",
                "color: var(--rui-muted-foreground)",
              ],
              title=current,
              current,
            ),
            @rui.button(
              variant=Ghost,
              size=Sm,
              disabled~,
              style=[UI_FONT_STYLE, "flex-shrink: 0"],
              title="Reload branch information",
              on_click=emit(GitEvent(GitRefresh(context.entry.id))),
              "Refresh",
            ),
          ],
        ),
        ..panel.info.map_or([], info => {
          guard info.available else {
            return [
              @rui.alert([
                @rui.alert_title("Git unavailable"),
                @rui.alert_description("Install Git to enable more features"),
              ]),
            ]
          }
          [git_branch_controls(context, panel, info, busy, emit)]
        }),
        git_output_view(panel, task),
      ],
    ),
  ]
}
