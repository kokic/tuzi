///|
fn open_with_items(
  scope : @rui.ContextMenuScope,
  target : OpenTarget,
  registry : @tuzi.OpenRegistry,
  emit : Emit[Msg],
) -> Array[Html] {
  let association = registry.for_entry(
    target.entry.name,
    is_dir=target.entry.is_dir(),
  )
  let items : Array[Html] = []
  for id in association.openers {
    let opener = registry.openers[id]
    guard target.unavailable_reason(opener.action) is None else { continue }
    items.push(
      @rui.context_menu_item(
        scope,
        on_select=emit(OpenWith(target, id)),
        span(style=status_text_style(), title=opener.label, opener.label),
      ),
    )
  }
  items
}
