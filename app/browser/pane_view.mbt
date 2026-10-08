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
        Unloaded | Loading => [@rui.spinner(label="Loading directory…")]
        LoadFailed(error) =>
          [directory_failure_view(error, pane.entries.is_empty(), idx, emit)]
        Ready =>
          if pane.entries.is_empty() {
            [@rui.empty(@rui.empty_header(@rui.empty_title("Empty directory")))]
          } else {
            []
          }
      },
    ),
    "entries": if pane.loading is (LoadFailed(_) | Ready) &&
      pane.entries.is_empty() {
      @html.nothing
    } else {
      rows
    },
    "details": data.entry_details_view(idx, pane.id, filter.unwrap_or(""), emit),
  })
}

///|
fn directory_failure_view(
  error : String,
  centered : Bool,
  idx : PaneSide,
  emit : Emit[Msg],
) -> Html {
  let retry = @rui.button(
    variant=Outline,
    size=Sm,
    on_click=emit(PaneEvent(ReloadPane(idx))),
    "Retry",
  )
  guard !centered else {
    @rui.empty(attrs=@html.Attrs::build().role("alert"), [
      @rui.empty_header([
        @rui.empty_title("Unable to read directory"),
        @rui.empty_description(error),
      ]),
      @rui.empty_content(retry),
    ])
  }
  @rui.alert(variant=Destructive, [
    @rui.alert_title("Unable to refresh directory"),
    @rui.alert_description(style=["overflow-wrap: anywhere"], error),
    @rui.alert_action(retry),
  ])
}
