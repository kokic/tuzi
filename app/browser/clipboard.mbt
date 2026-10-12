///|
fn Model::copy_selected_paths_to_clipboard(
  model : Model,
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard !context.items.is_empty() else { return (model, @rabbita.none) }
  let full = context.items.iter().map(item => item.path.to_string()).join("\n")
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
