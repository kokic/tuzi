///|
fn Model::copy_selected_paths_to_clipboard(
  model : Model,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  let items = pane.selected_items(filter?=model.entry_filter(model.active))
  guard !items.is_empty() else { return (model, @rabbita.none) }
  let full = items
    .iter()
    .map(entry => pane.path.join(Path("./\{entry.name}")).to_string())
    .join("\n")
  (
    model,
    @clipboard.copy(
      Text(full),
      copied=emit(Toast("Path copied", Some(full), @rui.ToastSuccess)),
      failed=err => {
        emit(Toast("Clipboard error", Some(err), @rui.ToastDestructive))
      },
    ),
  )
}
