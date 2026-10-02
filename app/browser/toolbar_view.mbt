///|
fn Model::toolbar_view(
  model : Model,
  panes : (PaneViewData, PaneViewData),
  emit : Emit[Msg],
) -> Html {
  let left = panes.0.entries.length()
  let right = panes.1.entries.length()
  let sel = model.panes.0.current.selected.length() +
    model.panes.1.current.selected.length()
  div(
    id="bar",
    style=toolbar_style(),
    [
      @rui.button(
        style=[UI_FONT_STYLE],
        variant=Ghost,
        size=Sm,
        on_click=emit(HelpOpen),
        "Help",
      ),
      @rui.button(
        style=[UI_FONT_STYLE],
        variant=Ghost,
        size=Sm,
        title="Choose how to open the file or folder under the cursor (o)",
        on_click=emit(OpenWithOpen),
        "Open with…",
      ),
      div(
        style=[
          "display: flex", "align-items: center", "gap: 6px", "font-size: var(--tuzi-footer-size)",
          "color: var(--rui-muted-foreground)", "white-space: nowrap", "padding-right: 8px",
        ],
        [
          span(style=count_style(model.active == Left), "\{left}"),
          span("·"),
          span(style=count_style(model.active == Right), "\{right}"),
          span("items"),
        ],
      ),
      ..if sel > 0 {
        [
          @rui.badge(
            style=[UI_FONT_STYLE],
            variant=Secondary,
            "\{sel} selected",
          ),
        ]
      },
      @rui.input_group(
        style=[
          UI_FONT_STYLE,
          "width: 100%",
          "max-width: 320px",
          "min-width: 0",
          "flex: 1 1 240px",
        ],
        [
          @rui.input_group_input(
            style=[UI_FONT_STYLE],
            id="filter-input",
            value=model.filter,
            placeholder="Filter files…",
            on_input=emit.map(text => FilterChanged(text)),
            attrs=@html.Attrs::build()
              .aria_label("Filter files")
              .on_focus(_ => emit(FilterFocus(true)))
              .on_blur(_ => emit(FilterFocus(false))),
          ),
          ..if !model.filter.is_empty() {
            [
              @rui.input_group_addon(
                align=InputInlineEnd,
                @rui.input_group_button(
                  style=[UI_FONT_STYLE],
                  title="Clear filter",
                  on_click=emit(FilterChanged("")),
                  "×",
                ),
              ),
            ]
          },
        ],
      ),
      model.status_view(emit),
      @rui.button(
        style=[UI_FONT_STYLE, "margin-left: auto"],
        variant=Ghost,
        size=Sm,
        title="Toggle light / dark theme",
        on_click=emit(ThemeToggle),
        match model.theme {
          Light => "Light"
          Dark => "Dark"
        },
      ),
    ],
  )
}

///|
fn Model::status_view(model : Model, emit : Emit[Msg]) -> Html {
  let latest = model.jobs.items.get(0)
  let error = model.jobs.error()
  let (message, indicator) : (String, Html?) = match () {
    _ if !error.is_empty() =>
      (
        error,
        Some(
          @rui.badge(
            style=[UI_FONT_STYLE, "flex-shrink: 0"],
            variant=Destructive,
            "Error",
          ),
        ),
      )
    _ if model.jobs.submitting =>
      (
        "Submitting operation…",
        Some(@rui.spinner(label="Submitting", style=["flex-shrink: 0"])),
      )
    _ =>
      latest.map_or(("Ready", None), task => {
        (task.summary(), Some(task_indicator(task.status)))
      })
  }
  div(
    id="status",
    style=status_style(),
    attrs=@html.Attrs::build().aria_label("Activity").aria_live("polite"),
    [
      @rui.button(
        variant=Ghost,
        size=Sm,
        style=[
          UI_FONT_STYLE,
          "min-width: 0",
          "width: 100%",
          "justify-content: flex-start",
        ],
        title="View activity history",
        on_click=emit(ActivityOpen),
        [
          ..indicator.map_or([], icon => [icon]),
          span(style=status_text_style(), message),
        ],
      ),
    ],
  )
}
