///|
fn git_output_view(panel : GitPanel, task : Task?) -> Html {
  let active = task.map_or(false, task => task.status.is_active())
  let running = task.map_or(false, task => task.status == Running)
  let pending = panel.loading || running
  let label = match () {
    _ if running => "Git operation running…"
    _ if active => "Git operation queued…"
    _ if panel.loading => "Loading Git information…"
    _ => "Output"
  }
  let task_error = task.map_or("", task => {
    match task.status {
      Failed(error) => error.message
      _ => ""
    }
  })
  let error = if panel.error.is_empty() { task_error } else { panel.error }
  guard error.is_empty() else {
    @rui.alert(variant=Destructive, [
      @rui.alert_title("Git error"),
      @rui.alert_description(task_output_view(error)),
    ])
  }
  let output = task.map_or("Git output will appear here.", task => {
    match task.status {
      Completed(output) => "Completed.\n" + output
      Queued => "Queued…"
      Running => "Running…"
      Failed(error) => error.message
    }
  })
  div(style=["display: grid", "gap: 8px", "min-width: 0"], [
    div(
      style=[
        "display: flex", "align-items: center", "gap: 8px", "min-width: 0", "min-height: 24px",
        "font-size: 0.8125rem",
      ],
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      [
        ..if pending {
          [@rui.spinner(label~, style=["flex-shrink: 0"])]
        },
        span(style=status_text_style(), title=label, label),
      ],
    ),
    task_output_view(output, label="Git output"),
  ])
}
