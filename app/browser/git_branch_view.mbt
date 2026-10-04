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
          style=[UI_FONT_STYLE],
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
          style=[UI_FONT_STYLE],
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
          style=[UI_FONT_STYLE],
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
