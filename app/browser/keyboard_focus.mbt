///|
fn filter_input_id(idx : PaneSide, view_id : Int32) -> String {
  "pane-\{idx.index()}-view-\{view_id}-filter"
}

///|
fn focus_filter_input(idx : PaneSide, view_id : Int32) -> Cmd {
  @rabbita.delay(
    @rabbita.effect(() => {
      guard @dom.document()
        .get_element_by_id(filter_input_id(idx, view_id))
        .to_option()
        is Some(element) &&
        element.to_html_element() is Some(input) else {
        return
      }
      input.focus()
    }),
    0,
  )
}

///|
fn blur_filter_input(idx : PaneSide, view_id : Int32) -> Cmd {
  @rabbita.effect(() => {
    guard @dom.document()
      .get_element_by_id(filter_input_id(idx, view_id))
      .to_option()
      is Some(element) &&
      element.to_html_element() is Some(input) else {
      return
    }
    input.blur()
  })
}
