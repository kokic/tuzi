///|
/// Reserve a bounded output area for success, errors and loading alike.
/// Preserve log lines and let this element, rather than the dialog, scroll.
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
    div(
      // The frame owns the border and background; the scroll viewport is a
      // separate child, so the border can never sit on the final line.
      style=[
        "width: 100%", "min-width: 0", "max-width: 100%", "height: 144px", "box-sizing: border-box",
        "border-radius: var(--rui-radius)", "background: var(--rui-muted)", "border: 1px solid var(--rui-border)",
      ],
      [
        div(
          style=[
            "width: 100%", "height: 100%", "box-sizing: border-box", "overflow: auto",
            "overscroll-behavior: contain",
          ],
          attrs=@html.Attrs::build().tabindex(0).aria_label("Git output"),
          [
            @html.pre(
              // Padding belongs to the text box, not the scroll container, so
              // the trailing space stays inside the scrollable content.
              style=[
                "margin: 0",
                "box-sizing: border-box",
                "width: max-content",
                "min-width: 100%",
                "white-space: pre",
                "overflow-wrap: normal",
                "word-break: normal",
                "padding: 12px",
                CODE_FONT_STYLE,
                "font-size: 0.75rem",
                "line-height: 1.6",
              ],
              output,
            ),
          ],
        ),
      ],
    ),
  ])
}
