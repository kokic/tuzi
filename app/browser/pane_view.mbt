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
  active : Bool,
  filter : String?,
  rows : Html,
  breadcrumbs : Html,
  sort_select : Html,
  history_menu : Html,
) -> Html {
  div(id="pane-\{idx.index()}-view-\{pane.id}", style=pane_style(active), {
    "header": div(class="phead", style=pane_header_style(active), breadcrumbs),
    "sort": div(
      style=[..pane_header_style(active), "justify-content: flex-end"],
      [
        history_menu,
        pane_filter_view(idx, pane.id, filter.unwrap_or(""), emit),
        @rui.button(
          variant=Ghost,
          size=Xs,
          style=[UI_FONT_STYLE, "flex: none"],
          title="Go to directory",
          on_click=emit(GotoEvent(Open(idx, pane.path))),
          "goto",
        ),
        sort_select,
      ],
    ),
    "content": div(
      style=[
        "position: relative", "display: flex", "flex-direction: column", "flex: 1",
        "min-width: 0", "min-height: 0",
      ],
      {
        "status": match pane.loading {
          Unloaded | Loading => @html.nothing
          LoadFailed(error) =>
            pane_status_scroll_view(
              directory_failure_view(error, pane.entries.is_empty(), idx, emit),
              fill=pane.entries.is_empty(),
            )
          Ready =>
            if pane.entries.is_empty() {
              pane_status_scroll_view(
                @rui.empty(
                  @rui.empty_header(@rui.empty_title("Empty directory")),
                ),
                fill=true,
              )
            } else {
              @html.nothing
            }
        },
        "entries": if pane.entries.is_empty() {
          @html.nothing
        } else {
          rows
        },
        "loading": if pane.loading is (Unloaded | Loading) {
          div(
            style=[
              "position: absolute", "inset: 0", "display: flex", "align-items: center",
              "justify-content: center", "pointer-events: none",
            ],
            @rui.spinner(label="Loading directory…"),
          )
        } else {
          @html.nothing
        },
      },
    ),
    "details": data.entry_details_view(),
  })
}

///|
fn pane_status_scroll_view(content : Html, fill~ : Bool) -> Html {
  @rui.scroll_area(
    attrs=@html.Attrs::build().aria_label("Directory status"),
    style=[
      "height: auto",
      "min-height: 0",
      ..if fill {
        ["flex: 1", "display: flex", "flex-direction: column"]
      } else {
        // A refresh error must leave room for the retained directory listing.
        ["flex: none", "max-height: 50%"]
      },
    ],
    content,
  )
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
