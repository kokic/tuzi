///|
fn Model::toolbar_view(model : Model, emit : Emit[Msg]) -> Html {
  let sel = model.panes.0.current.selected.length() +
    model.panes.1.current.selected.length()
  div(id="bar", class="tuzi-toolbar", [
    div(
      style=[
        "display: flex", "align-items: center", "gap: 8px", "min-width: 0", "overflow: hidden",
        "padding-right: 12px",
      ],
      [
        @rui.button(
          style=[@presentation.UI_FONT_STYLE],
          variant=Ghost,
          size=Sm,
          on_click=emit(HelpOpen),
          "Help",
        ),
        ..if sel > 0 {
          [
            span(
              style=[
                "font-variant-numeric: tabular-nums", "white-space: nowrap",
              ],
              "\{sel} selected",
            ),
          ]
        },
        @rui.button(
          style=[@presentation.UI_FONT_STYLE],
          variant=Ghost,
          size=Sm,
          on_click=@dialog.show(CommandDialogId),
          "Command",
        ),
        model.status_view(emit),
      ],
    ),
    div(
      attrs=@html.Attrs::build().aria_hidden("true"),
      style=["align-self: stretch", "background: var(--rui-border)"],
      @html.nothing,
    ),
    div(
      style=[
        "display: flex", "align-items: center", "gap: 8px", "min-width: 0", "overflow: hidden",
        "padding-left: 12px",
      ],
      [
        model.entry_details_view(model.pane_at(model.active)),
        @rui.button(
          style=[@presentation.UI_FONT_STYLE],
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
    ),
  ])
}

///|
fn Model::status_view(model : Model, emit : Emit[Msg]) -> Html {
  let latest = model.jobs.items.get(0)
  let error = model.jobs.error()
  let (message, indicator) : (String, Html?) = match () {
    _ if !error.is_empty() => (error, Some(badge(variant=Destructive, "Error")))
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
    class="tuzi-status",
    attrs=@html.Attrs::build().aria_label("Activity").aria_live("polite"),
    [
      @rui.button(
        variant=Ghost,
        size=Sm,
        style=[
          @presentation.UI_FONT_STYLE,
          "min-width: 0",
          "width: 100%",
          "justify-content: flex-start",
        ],
        title="View activity history",
        on_click=emit(ActivityOpen),
        [
          ..indicator.map_or([], icon => [icon]),
          span(class="tuzi-status-text", message),
        ],
      ),
    ],
  )
}
