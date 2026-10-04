///|
fn panes_view(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  model
  .map(model => {
    (model.entry_appearance, model.openers, model.supports_drive_selection)
  })
  .switch_by(
    configuration => {
      let (appearance, openers, supports_drives) = configuration
      pane_stack_view(model, Left, emit, appearance, openers, supports_drives).view2(
        pane_stack_view(
          model,
          Right,
          emit,
          appearance,
          openers,
          supports_drives,
        ),
        (left, right) => div(id="panes", style=panes_style(), [left, right]),
      )
    },
    by=configuration => ToJson::to_json(configuration).stringify(),
  )
}

///|
fn Pane::pane_view(
  pane : Pane,
  data : PaneViewData,
  idx : PaneSide,
  emit : Emit[Msg],
  sort : SortMode,
  active : Bool,
  filter : String?,
  rows : Html,
  drive_menu~ : Html?,
) -> Html {
  let sort_label = match sort {
    Name => "name"
    Size => "size"
    Time => "time"
  }
  div(id="pane-\{idx.index()}-view-\{pane.id}", style=pane_style(active), {
    "header": breadcrumbs_view(
      pane.path,
      sort_label,
      idx,
      emit,
      pane_header_style(active),
      drive_menu~,
    ),
    "status": fragment(
      match pane.loading {
        Unloaded | Loading =>
          [
            @rui.field_description(
              style=pane_status_style(),
              "Loading directory…",
            ),
          ]
        LoadFailed(error) =>
          [
            div(style=pane_status_style(), [
              @rui.field_error(error),
              @rui.button(
                style=[UI_FONT_STYLE],
                variant=Outline,
                on_click=emit(PaneEvent(ReloadPane(idx))),
                "Retry",
              ),
            ]),
          ]
        Ready =>
          if pane.entries.is_empty() {
            [
              @rui.field_description(
                style=pane_status_style(),
                "Empty directory",
              ),
            ]
          } else {
            []
          }
      },
    ),
    "entries": rows,
    "details": data.entry_details_view(idx, pane.id, filter.unwrap_or(""), emit),
  })
}
