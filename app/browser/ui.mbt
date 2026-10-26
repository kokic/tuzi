///|
fn kbd(key : String) -> Html {
  @rui.kbd(style=[CODE_FONT_STYLE], key)
}

///|
fn centered_loading_view(label : String) -> Html {
  @rui.empty(
    @rui.empty_content(
      style=["flex-direction: row", "justify-content: center"],
      [@rui.spinner(label~, style=["flex: none"]), span(label)],
    ),
  )
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
fn text_input_field_view(
  id~ : String,
  label~ : String,
  value~ : String,
  error~ : String,
  on_input~ : Emit[String],
  autofocus~ : Bool = false,
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
