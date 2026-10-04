///|
fn name_dialog(
  title : String,
  prompt : String,
  input : String,
  error : String,
  emit : Emit[Msg],
) -> Html {
  modal(title, emit, [
    dialog_input(prompt, input, error, emit),
    dialog_footer(emit, "OK", Default, has_input=true),
  ])
}

///|
fn new_entry_dialog(input : String, error : String, emit : Emit[Msg]) -> Html {
  modal("New file or folder", emit, [
    dialog_input("Name:", input, error, emit),
    @rui.dialog_description("Enter to create folder · Esc to cancel"),
    @rui.dialog_footer([
      dialog_close_button("Cancel"),
      @rui.button(
        style=[UI_FONT_STYLE],
        variant=Outline,
        on_click=emit(NewEntrySubmit(File)),
        "File",
      ),
      @rui.button(
        style=[UI_FONT_STYLE],
        on_click=emit(NewEntrySubmit(Folder)),
        "Folder",
      ),
    ]),
  ])
}

///|
fn zip_dialog(
  input : String,
  level : Int,
  error : String,
  emit : Emit[Msg],
) -> Html {
  modal("Compress to ZIP", emit, [
    dialog_input("Archive name:", input, error, emit),
    @rui.field(style=["margin-top: 1rem"], [
      @rui.field_label(for_="zip-level", "Compression level:"),
      @rui.native_select(
        id="zip-level",
        value=level.to_string(),
        style=[UI_FONT_STYLE, "width: 100%"],
        wrapper_style=["width: 100%"],
        attrs=@html.Attrs::build().aria_describedby("zip-level-description"),
        on_change=emit.map(value => ZipLevelChanged(value)),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(option => {
          @rui.native_select_option(
            value=option.to_string(),
            selected=option == level,
            match option {
              0 => "0 — No compression"
              1 => "1 — Fastest"
              6 => "6 — Normal (default)"
              9 => "9 — Maximum compression"
              _ => option.to_string()
            },
          )
        }),
      ),
      @rui.field_description(
        id="zip-level-description",
        "Higher levels favor smaller files over speed. Already-compressed file types are stored without recompression.",
      ),
    ]),
    dialog_footer(emit, "Compress", Default, has_input=true),
  ])
}

///|
fn dialog_footer(
  emit : Emit[Msg],
  confirm : String,
  variant : @rui.ButtonVariant,
  has_input? : Bool = false,
) -> Html {
  fragment([
    @rui.dialog_description("Enter to confirm · Esc to cancel"),
    dialog_confirm_footer_view(
      label=confirm,
      on_confirm=emit(DialogSubmit),
      variant~,
      autofocus=!has_input,
    ),
  ])
}

///|
fn dialog_input(
  prompt : String,
  value : String,
  error : String,
  emit : Emit[Msg],
) -> Html {
  form(on_submit=emit(DialogSubmit), [
    text_input_field_view(
      id="dialog-input",
      label=prompt,
      value~,
      error~,
      autofocus=true,
      on_input=emit.map(text => DialogInput(text)),
    ),
  ])
}
