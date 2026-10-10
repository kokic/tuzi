// Application-level wrappers for rui components.

///|
fn kbd(key : String) -> Html {
  @rui.kbd(style=[CODE_FONT_STYLE], key)
}

///|
fn[C : @html.IsChildren] badge(
  variant~ : @rui.BadgeVariant,
  attrs? : @html.Attrs,
  children : C,
) -> Html {
  @rui.badge(
    variant~,
    attrs?,
    style=[UI_FONT_STYLE, "border-radius: 4px"],
    children,
  )
}

///|
/// Stable id shared by every application dialog. The native `<dialog>` keeps
/// the browser-owned open state across content changes between dialogs.
const DialogId : String = "tuzi-dialog"

///|
const DialogTitleId : String = "tuzi-dialog-title"

///|
const DialogDescriptionId : String = "tuzi-dialog-description"

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
  description? : String,
) -> Html {
  let attrs = @html.Attrs::build()
    .aria_labelledby(DialogTitleId)
    .on_keydown(event => handle_dialog_keyboard_event(event, emit))
  if description is Some(_) {
    ignore(attrs.aria_describedby(DialogDescriptionId))
  }
  @rui.dialog(
    id=DialogId,
    attrs~,
    on_close=_ => emit(DialogCancel),
    style=[
      UI_FONT_STYLE,
      "overflow-wrap: anywhere",
      ..match size {
        Small => []
        Wide => ["width: min(640px, calc(100% - 2rem))"]
        Reading => ["width: 960px", "max-width: calc(100vw - 32px)"]
      },
      ..style,
    ],
    [
      @rui.dialog_header(
        [
          @rui.dialog_title(id=DialogTitleId, title),
          ..description.map_or([], description => {
            [@rui.dialog_description(id=DialogDescriptionId, description)]
          }),
        ],
      ),
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
  description? : String,
) -> Html {
  let error_id = id + "-error"
  let description_id = id + "-description"
  let attrs = @html.Attrs::build()
  let describedby = description.map_or([], _ => [description_id])
  if !error.is_empty() {
    describedby.push(error_id)
  }
  if !describedby.is_empty() {
    ignore(attrs.aria_describedby(describedby.join(" ")))
  }
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
        attrs~,
      ),
      ..description.map_or([], description => {
        [@rui.field_description(id=description_id, description)]
      }),
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
fn dialog_keyboard_hint_view(action : String) -> Html {
  p(
    style=[
      "margin: 0", "width: 100%", "color: var(--rui-muted-foreground)", "font-size: 0.875rem",
      "line-height: 1.5",
    ],
    [kbd("Enter"), span(" to \{action} · "), kbd("Esc"), span(" to cancel")],
  )
}

///|
fn dialog_confirm_footer_view(
  label~ : String,
  on_confirm~ : Cmd,
  variant? : @rui.ButtonVariant = Default,
  autofocus? : Bool = false,
) -> Html {
  @rui.dialog_footer([
    dialog_keyboard_hint_view("confirm"),
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
