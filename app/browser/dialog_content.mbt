///|
/// Stable id shared by every application dialog. The native `<dialog>` keeps
/// the browser-owned open state across content changes between dialogs.
const DialogId : String = "tuzi-dialog"

///|
const DialogTitleId : String = "tuzi-dialog-title"

///|
fn dialog_view(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  model.map(model => {
    let name_input = (title, prompt, input) => {
      name_dialog(title, prompt, input, model.dialog_error, emit)
    }
    match model.dialog {
      None => @html.nothing
      Help =>
        modal("Help", emit, [
          div(style=help_list_style(), help_lines()),
          @rui.field_description(style=["margin-top: 1rem"], "Esc to close"),
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
          @rui.field_description(
            style=["overflow-wrap: anywhere"],
            "Archive: \{source}",
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
fn modal(
  title : String,
  emit : Emit[Msg],
  children : Array[Html],
  style? : Array[String] = [],
) -> Html {
  @rui.dialog(
    id=DialogId,
    attrs=@html.Attrs::build()
      .aria_labelledby(DialogTitleId)
      .on_keydown(event => handle_dialog_keyboard_event(event, emit)),
    on_close=_ => emit(DialogCancel),
    style=[UI_FONT_STYLE, "background: var(--rui-card)", ..style],
    [
      @rui.dialog_header([@rui.dialog_title(id=DialogTitleId, title)]),
      ..children,
    ],
  )
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
    div(style=help_row_style(), [
      @rui.kbd(style=[UI_FONT_STYLE, "justify-self: start"], key),
      @rui.field_description(desc),
    ])
  })
}
