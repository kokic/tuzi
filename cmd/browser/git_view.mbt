///|
fn git_info_dialog(
  context : GitContext,
  jobs : TaskState,
  emit : Emit[Msg],
) -> Html {
  let content = git_info_content(
    context,
    latest_git_task(jobs.items, context.entry.path),
    jobs.submitting,
    emit,
  )
  context.entry.dialog(content, emit, expanded=true)
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
              @rui.field_description("Install Git to enable more features"),
            ]
          }
          [git_branch_controls(context, panel, info, busy, emit)]
        }),
        git_output_view(panel, task),
      ],
    ),
  ]
}

///|
fn git_branch_controls(
  context : GitContext,
  panel : GitPanel,
  info : @tuzi.GitInfo,
  busy : Bool,
  emit : Emit[Msg],
) -> Html {
  let disabled = panel.loading || busy
  div(style=["display: grid", "gap: 12px", "min-width: 0"], [
    div(
      style=["display: flex", "flex-wrap: wrap", "gap: 8px", "min-width: 0"],
      [
        git_branch_select(context.entry.id, panel, info, busy, emit),
        @rui.button(
          variant=Secondary,
          disabled=disabled ||
            !info.branches.any(branch => {
              branch.reference == panel.selected &&
              !git_branch_is_current(branch, info)
            }),
          style=[UI_FONT_STYLE, "flex-shrink: 0"],
          on_click=emit(
            GitEvent(GitRun(context.entry.id, Switch(panel.selected))),
          ),
          "Switch",
        ),
        @rui.button(
          variant=Secondary,
          disabled=disabled ||
            !info.branches.any(branch => {
              branch.reference == panel.selected &&
              git_branch_can_rename(branch)
            }),
          style=[UI_FONT_STYLE, "flex-shrink: 0"],
          title="git branch -m",
          on_click=emit(GitEvent(GitRenameOpen(context.entry.id))),
          "Rename",
        ),
        @rui.button(
          variant=Destructive,
          disabled=disabled ||
            !info.branches.any(branch => {
              branch.reference == panel.selected &&
              git_branch_can_delete(branch, info)
            }),
          style=[UI_FONT_STYLE, "flex-shrink: 0"],
          title="git branch -D",
          on_click=emit(
            GitEvent(GitRun(context.entry.id, DeleteBranch(panel.selected))),
          ),
          "Delete",
        ),
      ],
    ),
    div(
      style=[
        "display: grid", "grid-template-columns: repeat(auto-fit, minmax(min(100%, 120px), 1fr))",
        "gap: 8px",
      ],
      [
        @rui.button(
          variant=Outline,
          disabled~,
          style=[UI_FONT_STYLE, "min-width: 0"],
          title="Pull changes from the configured upstream (fast-forward only)",
          on_click=emit(GitEvent(GitRun(context.entry.id, Pull))),
          "↓ Pull",
        ),
        @rui.button(
          variant=Outline,
          disabled~,
          style=[UI_FONT_STYLE, "min-width: 0"],
          title="Push changes to the configured remote",
          on_click=emit(GitEvent(GitRun(context.entry.id, Push))),
          "↑ Push",
        ),
        @rui.button(
          variant=Outline,
          disabled~,
          style=[UI_FONT_STYLE, "min-width: 0"],
          title="git remote prune origin",
          on_click=emit(GitEvent(GitRun(context.entry.id, Prune))),
          "* Prune",
        ),
      ],
    ),
  ])
}

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
  let output = if !error.is_empty() {
    error
  } else {
    task.map_or("Git output will appear here.", task => {
      match task.status {
        Completed(output) => "Completed.\n" + output
        Queued => "Queued…"
        Running => "Running…"
        Failed(error) => error.message
      }
    })
  }
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
        "width: 100%",
        "min-width: 0",
        "max-width: 100%",
        "height: 144px",
        "box-sizing: border-box",
        "border-radius: var(--rui-radius)",
        "background: var(--rui-muted)",
        "border: 1px solid var(--rui-border)",
        ..if !error.is_empty() {
          ["border-color: var(--rui-destructive)"]
        },
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
