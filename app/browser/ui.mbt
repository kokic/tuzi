// Application-level wrappers for rui components.

///|
fn kbd(key : String) -> Html {
  @rui.kbd(style=[CODE_FONT_STYLE], key)
}

///|
/// Stable id shared by every application dialog. The native `<dialog>` keeps
/// the browser-owned open state across content changes between dialogs.
const DialogId : String = "tuzi-dialog"

///|
const DialogTitleId : String = "tuzi-dialog-title"

///|
priv enum ModalSize {
  Small
  Wide
  Reading
}

///|
fn modal(
  title : String,
  emit : Emit[Msg],
  children : Array[Html],
  size? : ModalSize = Small,
  style? : Array[String] = [],
) -> Html {
  @rui.dialog(
    id=DialogId,
    attrs=@html.Attrs::build()
      .aria_labelledby(DialogTitleId)
      .on_keydown(event => handle_dialog_keyboard_event(event, emit)),
    on_close=_ => emit(DialogCancel),
    style=[
      UI_FONT_STYLE,
      ..match size {
        Small => []
        Wide => ["width: min(640px, calc(100% - 2rem))"]
        Reading => ["width: 960px", "max-width: calc(100vw - 32px)"]
      },
      ..style,
    ],
    [
      @rui.dialog_header([@rui.dialog_title(id=DialogTitleId, title)]),
      ..children,
    ],
  )
}

///|
fn text_input_field_view(
  id~ : String,
  label~ : String,
  value~ : String,
  error~ : String,
  on_input~ : Emit[String],
  autofocus? : Bool = false,
) -> Html {
  let error_id = id + "-error"
  @rui.field(
    invalid=!error.is_empty(),
    [
      @rui.field_label(for_=id, label),
      @rui.input(
        style=[UI_FONT_STYLE],
        id~,
        value~,
        autofocus~,
        on_input~,
        invalid=!error.is_empty(),
        attrs=@html.Attrs::build().aria_describedby(
          if error.is_empty() {
            ""
          } else {
            error_id
          },
        ),
      ),
      ..if !error.is_empty() {
        [@rui.field_error(id=error_id, error)]
      },
    ],
  )
}

///|
fn dialog_close_button(label : String, autofocus? : Bool = false) -> Html {
  form(method_="dialog", [
    @rui.button(
      style=[UI_FONT_STYLE],
      variant=Outline,
      type_="submit",
      autofocus~,
      label,
    ),
  ])
}

///|
fn dialog_confirm_footer_view(
  label~ : String,
  on_confirm~ : Cmd,
  variant? : @rui.ButtonVariant = Default,
  autofocus? : Bool = false,
) -> Html {
  @rui.dialog_footer([
    dialog_close_button("Cancel"),
    @rui.button(
      style=[UI_FONT_STYLE],
      variant~,
      autofocus~,
      on_click=on_confirm,
      label,
    ),
  ])
}

///|
fn dialog_close_footer_view(
  label? : String = "Close",
  actions? : Array[Html] = [],
) -> Html {
  @rui.dialog_footer([..actions, dialog_close_button(label, autofocus=true)])
}
