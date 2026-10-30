///|
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
  size~ : ModalSize = Small,
  style~ : Array[String] = [],
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
      "border-radius: var(--rui-radius)",
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
fn dialog_close_button(label : String, autofocus~ : Bool = false) -> Html {
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
  variant~ : @rui.ButtonVariant = Default,
  autofocus~ : Bool = false,
  disabled~ : Bool = false,
) -> Html {
  @rui.dialog_footer(style=dialog_footer_style, [
    dialog_keyboard_hint_view("confirm"),
    dialog_close_button("Cancel"),
    @rui.button(
      style=[UI_FONT_STYLE],
      variant~,
      autofocus~,
      disabled~,
      on_click=on_confirm,
      label,
    ),
  ])
}

///|
fn dialog_close_footer_view(
  label~ : String = "Close",
  actions~ : Array[Html] = [],
) -> Html {
  @rui.dialog_footer(
    style=dialog_footer_style,
    [..actions, dialog_close_button(label, autofocus=true)],
  )
}
