///|
fn help_dialog(emit : Emit[Msg]) -> Html {
  modal(
    "Help",
    emit,
    size=Wide,
    style=[
      "max-height: calc(100dvh - 32px)", "display: flex", "flex-direction: column",
      "overflow: hidden",
    ],
    [
      @rui.scroll_area(
        style=["height: auto", "max-height: 65vh", "min-height: 0"],
        attrs=@html.Attrs::build().aria_label("Operating guide"),
        [
          @rui.table([
            @rui.table_caption(
              style=["color: currentColor"],
              "Keyboard shortcuts",
            ),
            @rui.table_body(help_lines()),
          ]),
          ..help_sections(),
        ],
      ),
      dialog_close_footer_view(),
    ],
  )
}

///|
fn help_lines() -> Array[Html] {
  let binds = [
    ("Tab / ← / →", "Switch active pane"),
    ("↑ / ↓", "Move the file cursor"),
    ("Space", "Toggle selection and move to the next item"),
    ("Enter", "Open the cursor item / enter directory / extract ZIP"),
    ("a / Right-click", "Open file or folder actions"),
    ("Esc", "Go up a directory; leave a filter or close a dialog"),
    ("c / m", "Copy / move selected items to the other pane"),
    ("d", "Delete selected items"),
    ("r", "Rename one selected item"),
    ("i", "Show information about the cursor item"),
    ("z", "Compress selected items to ZIP"),
    ("n", "Create a file or folder in the active pane"),
    ("s", "Cycle the active pane's sort order"),
    ("y", "Copy selected items' full paths"),
    ("f", "Focus the active pane's file filter"),
    ("?", "Open Help"),
  ]
  binds.map(pair => {
    let (key, desc) = pair
    @rui.table_row([
      @rui.table_cell(style=["text-align: right"], kbd(key)),
      @rui.table_cell(style=["text-align: left", "white-space: normal"], desc),
    ])
  })
}

///|
fn help_sections() -> Array[Html] {
  let sections = [
    (
      "Browsing and selection", "Click an item to activate its pane and move the cursor. Double-click its name to open it; use the checkboxes or Space to select multiple items. Copy, move, delete, ZIP compression, and path copying use selected items, or the cursor item when nothing is selected. Rename requires one item. Information and opening use the cursor item. File shortcuts apply while browsing, rather than while typing in an input or using a dialog or menu.",
    ),
    (
      "Directory paths", "Click a directory name in the path at the top of a pane to navigate to it. Click the current directory name to reload it. Where storage locations are available, click or right-click the root dropdown to choose a drive or mount. Command → View: Synchronize to Current Panel Path opens the active pane's directory in the other pane. Your last directories and active pane are restored on the next launch without an explicit startup path.",
    ),
    (
      "Filtering and sorting", "Type in the filter at the bottom of a pane to match file names; filtering is case-sensitive. Click × to clear it. Esc leaves the input without clearing the filter. Operations only include selected items visible under the filter. Click a pane's sort button, or press s in the active pane, to cycle name → size → time. Folders appear first; sizes sort largest first and dates newest first. Each pane keeps its own filter and sort order.",
    ),
    (
      "File actions", "Right-click an item, or press a on the cursor item, to open its actions and available opening choices. Acting on an item already in the selection uses that selection; acting on another item targets that item. Copy and move send items to the directory shown in the other pane, so the two pane paths must differ. Delete asks for confirmation. Rename and New file or folder open name inputs; in the latter, use File or Folder, or press Enter to create a folder.",
    ),
    (
      "Archives", "Compress to ZIP asks for an archive name and a compression level from 0 (no compression) to 9 (maximum), with 6 as the default. Opening a ZIP offers extraction: enter a new destination directory, using / as the path separator. Relative destinations start from the archive's directory, and an existing destination directory is not overwritten.",
    ),
    (
      "Information and previews", "Information shows an item's type, size, full path, and modification time in UTC. Click the displayed path to copy it. Images also show a preview. For symbolic links, edit the full link path or full target path and choose Save; moving or renaming a link uses its Information fields. Markdown opens with Preview and Code tabs; other previewable files open in a browser tab. The actions menu offers the opening choices configured for that item.",
    ),
    (
      "Command", "Click Command in the bottom bar, then type to search its commands. Use ↑ / ↓ and Enter to choose a command, or click it; Esc closes the panel. In addition to pane synchronization and bookmarks, it provides contribution and navigation links that open in a new tab.",
    ),
    (
      "Bookmarks", "Command → Bookmarks: Add Current Panel Path saves the active pane's directory, with duplicate paths ignored. Command → Bookmarks: View All opens the shared bookmark list. Jump opens a bookmark in the pane that was active when the list opened, preserving that pane's sort order. Delete removes only the bookmark and keeps the list open. Bookmarks persist across refreshes and launches in the same browser and site address; a failed save is reported in a notification.",
    ),
    (
      "Activity", "Click the status in the bottom bar to view queued, running, completed, and failed operations. Choose Output or Error details to open a separate large dialog with vertical and horizontal scrolling; Back to Activity returns to the history. ZIP and Git tasks also offer View progress or View details. Closing or hiding a task dialog does not cancel the operation; it continues even if the page is refreshed. If a directory fails to load, use its Retry button.",
    ),
    (
      "Git", "Open Information on a .git entry to view its Git panel. Select a branch and choose Switch; local branches can also be renamed, and a non-current local branch can be forcibly deleted. Pull uses the configured upstream and accepts only a fast-forward; Push uses the configured remote. Prune removes stale origin tracking references. Refresh reloads branch information, and task output shows operation results. Git must be installed to use these controls.",
    ),
    (
      "Theme and dialogs", "Click Light or Dark in the bottom bar to switch themes. In dialogs, Tab moves between controls and Enter activates a focused button or submits an input. Esc or Close dismisses a dialog. While a menu is open, use its arrow keys and Enter to select an action, or Esc to dismiss it.",
    ),
  ]
  sections.map(section => {
    let (title, body) = section
    div(style=["margin-top: 1rem", "padding-inline: 4px"], [
      @html.h3(style=["margin: 0 0 0.5rem", "font-size: 0.875rem"], title),
      p(style=["margin: 0", "line-height: 1.6"], body),
    ])
  })
}
