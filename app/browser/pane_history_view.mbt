///|
fn pane_history_menu_view(
  id : String,
  current : Path,
  history : Set[String],
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  pane_path_menu_view(
    id,
    current,
    history.to_array().rev_iter().to_array(),
    idx,
    emit,
    label="History",
  )
}
