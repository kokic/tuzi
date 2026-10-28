///|
fn git_worktree_controls(
  context : GitContext,
  panel : GitPanel,
  info : @tuzi.GitInfo,
  busy : Bool,
  emit : Emit[Msg],
) -> Html {
  let disabled = panel.loading || busy
  div(
    style=[
      "display: grid", "gap: 8px", "min-width: 0", "padding-top: 12px", "border-top: 1px solid var(--rui-border)",
    ],
    [
      div(
        style=[
          "display: flex", "align-items: center", "gap: 12px", "min-width: 0",
        ],
        [
          p(
            style=["margin: 0", "font-weight: 600", "flex-shrink: 0"],
            "Worktrees",
          ),
          span(
            style=[
              ..status_text_style(),
              "flex: 1",
              "font-size: 0.8125rem",
              "color: var(--rui-muted-foreground)",
            ],
            "\{info.worktrees.length()} registered",
          ),
          @rui.button(
            variant=Ghost,
            size=Sm,
            disabled~,
            style=[UI_FONT_STYLE],
            title="git worktree prune",
            on_click=emit(GitEvent(GitRun(context.entry.id, PruneWorktrees))),
            "Prune stale",
          ),
        ],
      ),
      @rui.item_group(
        style=["--rui-item-group-gap: 6px"],
        Map::from_iter(
          info.worktrees
          .iter()
          .map(worktree => {
            (
              worktree.path.to_string(),
              git_worktree_item(context, worktree, disabled, emit),
            )
          }),
        ),
      ),
    ],
  )
}

///|
fn git_worktree_item(
  context : GitContext,
  worktree : @tuzi.GitWorktree,
  disabled : Bool,
  emit : Emit[Msg],
) -> Html {
  @rui.item(
    variant=ItemOutline,
    attrs=@html.Attrs::build().role("listitem"),
    style=["flex-wrap: nowrap", "padding: 6px 10px"],
    [
      @rui.item_content([
        @rui.item_title(
          [
            span(
              style=status_text_style(),
              title=worktree.path.to_string() +
                "\nBranch: " +
                git_worktree_branch_label(worktree),
              worktree.label(),
            ),
            ..git_worktree_badges(worktree),
          ],
        ),
      ]),
      @rui.item_actions(style=["flex-shrink: 0"], [
        @rui.button(
          variant=Destructive,
          size=Sm,
          style=[UI_FONT_STYLE],
          disabled=disabled || !worktree.can_remove(),
          title=git_worktree_remove_title(worktree),
          attrs=@html.Attrs::build().aria_label(
            "Delete worktree \{worktree.path}",
          ),
          on_click=emit(
            GitEvent(GitWorktreeRemoveOpen(context.entry.id, worktree.path)),
          ),
          "Delete",
        ),
      ]),
    ],
  )
}

///|
fn git_worktree_badges(worktree : @tuzi.GitWorktree) -> Array[Html] {
  let badges : Array[Html] = []
  if worktree.main {
    badges.push(badge(variant=Secondary, "main"))
  }
  if worktree.current {
    badges.push(badge(variant=Outline, "current"))
  }
  if worktree.bare {
    badges.push(badge(variant=Outline, "bare"))
  }
  if worktree.locked {
    badges.push(badge(variant=Destructive, "locked"))
  }
  if worktree.prunable {
    badges.push(badge(variant=Ghost, "missing"))
  }
  badges
}

///|
fn git_worktree_branch_label(worktree : @tuzi.GitWorktree) -> String {
  match worktree.branch_name() {
    Some(name) => name
    None =>
      if worktree.detached {
        "detached at " + worktree.short_head()
      } else {
        "none"
      }
  }
}

///|
fn git_worktree_remove_title(worktree : @tuzi.GitWorktree) -> String {
  guard !worktree.can_remove() else {
    return if worktree.prunable {
      "git worktree remove (forgets a worktree whose directory is already gone)"
    } else {
      "git worktree remove"
    }
  }
  if worktree.main {
    "The main worktree cannot be removed"
  } else if worktree.current {
    "This is the worktree the dialog was opened from"
  } else if worktree.bare {
    "A bare repository has no working tree to remove"
  } else {
    "Unlock the worktree first (git worktree unlock)"
  }
}
