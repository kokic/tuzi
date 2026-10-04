///|
fn dialog_view(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  model.map(model => {
    let name_input = (title, prompt, input) => {
      name_dialog(title, prompt, input, model.dialog_error, emit)
    }
    match model.dialog {
      None => @html.nothing
      Help =>
        modal("Help", emit, size=Wide, [
          @rui.table([
            @rui.table_caption(style=["color: currentColor"], HelpTableCaption),
            @rui.table_body(help_lines()),
          ]),
        ])
      Activity => activity_dialog(model.jobs.items, emit)
      Progress(batch) => progress_dialog(batch, emit)
      TaskDetails(id) => task_details_dialog(model.jobs.items, id, emit)
      Info(context) => context.dialog([], emit, error=model.dialog_error)
      Markdown(context) => context.dialog(emit)
      GitInfo(context) =>
        git_info_dialog(context, model.jobs, emit, error=model.dialog_error)
      DeleteConfirm(names~, ..) =>
        modal(
          "Delete \{names.length()} item(s)?",
          emit,
          [
            ..names.map(name => p(name)),
            dialog_footer(emit, "Delete", Destructive),
          ],
        )
      RenameInput(original~, input~, ..) =>
        name_input("Rename", "Rename \{original} to:", input)
      ZipInput(input~, level~, ..) =>
        zip_dialog(input, level, model.dialog_error, emit)
      UnzipInput(source~, input~) =>
        modal("Extract ZIP", emit, [
          @rui.item(
            @rui.item_content([
              @rui.item_title("Archive"),
              @rui.item_description(source.to_string()),
            ]),
          ),
          dialog_input(
            "Destination directory:",
            input,
            model.dialog_error,
            emit,
          ),
          @rui.field_description(
            "Creates a new directory; existing directories are not overwritten. Relative paths start from the archive's directory. Use / as the path separator.",
          ),
          dialog_footer(emit, "Extract", Default, has_input=true),
        ])
      NewEntryInput(input~, ..) =>
        new_entry_dialog(input, model.dialog_error, emit)
      GitRenameInput(input~, ..) =>
        name_input("Rename branch", "New branch name:", input)
    }
  })
}

///|
fn help_lines() -> Array[Html] {
  let binds = [
    ("Tab/←/→", "switch pane"),
    ("↑↓", "move cursor"),
    ("Space", "select"),
    ("Enter", "open file / enter directory / extract ZIP"),
    ("Right-click", "open file / folder actions"),
    ("Esc", "up / cancel"),
    ("c/m", "copy / move to other pane"),
    ("d", "delete"),
    ("r", "rename"),
    ("i", "file / folder information"),
    ("z", "compress to ZIP"),
    ("n", "new file / folder"),
    ("s", "sort"),
    ("y", "copy path"),
    ("f", "filter active pane"),
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
const HelpTableCaption : String = "ONLY APPLE CAN'T DO"
