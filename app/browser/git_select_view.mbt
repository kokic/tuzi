///|
fn git_branch_select(
  context_id : Int,
  panel : GitPanel,
  info : @tuzi.GitInfo,
  busy : Bool,
  emit : Emit[Msg],
) -> Html {
  @rui.native_select(
    id="git-branch-\{context_id}",
    value=panel.selected,
    disabled=busy || panel.loading || info.branches.is_empty(),
    aria_label="Select a branch",
    title=panel.selected,
    // Bound both the flex item and its control independently of option text.
    wrapper_style=[
      "flex: 1 1 200px", "width: 100%", "min-width: 0", "max-width: 100%",
    ],
    style=[
      UI_FONT_STYLE,
      "width: 100%",
      "min-width: 0",
      "max-width: 100%",
      "overflow: hidden",
      "white-space: nowrap",
      "text-overflow: ellipsis",
    ],
    on_change=emit.map(value => GitEvent(GitSelectBranch(context_id, value))),
    [
      @rui.native_select_option(value="", disabled=true, "Select a branch…"),
      ..info.branches.map(branch => {
        @rui.native_select_option(
          value=branch.reference,
          if branch.is_remote() {
            "\{branch.name} (remote)"
          } else {
            branch.name
          },
        )
      }),
    ],
  )
}
