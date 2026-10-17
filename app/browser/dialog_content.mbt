///|
fn dialog_view(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  let activity = activity_dialog(model.map(model => model.jobs), emit)
  model.view2(activity, (model, activity) => {
    let name_input = (title, prompt, input) => {
      name_dialog(title, prompt, input, model.dialog_error, emit)
    }
    match model.dialog {
      None => @html.nothing
      Help => help_dialog(emit)
      Activity => activity
      Bookmarks(side) => bookmarks_dialog(model.bookmarks, side, emit)
      Goto(context) => goto_dialog(context, model.dialog_error, emit)
      Progress(batch) => progress_dialog(batch, emit)
      TaskDetails(id) => task_details_dialog(model.jobs.items, id, emit)
      Info(context) => context.dialog([], emit, error=model.dialog_error)
      Markdown(context) => context.dialog(emit)
      TextPreview(context) => context.dialog(emit)
      GitInfo(context) =>
        git_info_dialog(context, model.jobs, emit, error=model.dialog_error)
      DeleteConfirm(directory~, names~) =>
        delete_confirm_dialog(
          "Delete \{names.length()} item(s)?",
          "The selected files and directories will be permanently deleted, including directory contents.",
          names.map(name => {
            (name, directory.join(Path("./\{name}")).to_string())
          }),
          emit,
        )
      BookmarkDeleteConfirm(path~, ..) =>
        delete_confirm_dialog(
          "Delete bookmark?",
          "Only the bookmark will be removed. The directory and its files will be kept.",
          [("Bookmarked directory", path.to_string())],
          emit,
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
            description="Creates a new directory; existing directories are not overwritten. Relative paths start from the archive's directory. Use / as the path separator.",
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
fn delete_confirm_dialog(
  title : String,
  description : String,
  items : Array[(String, String)],
  emit : Emit[Msg],
) -> Html {
  modal(title, emit, description~, [
    @rui.scroll_area(
      style=["height: auto", "max-height: 60vh"],
      @rui.item_group(
        Map::from_iter(
          items
          .iter()
          .map(item => {
            let (label, detail) = item
            (
              detail,
              @rui.item(
                @rui.item_content([
                  @rui.item_title(label),
                  @rui.item_description(detail),
                ]),
              ),
            )
          }),
        ),
      ),
    ),
    dialog_footer(emit, "Delete", Destructive),
  ])
}
