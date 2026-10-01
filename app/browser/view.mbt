///|
fn Model::view(
  model : Model,
  emit : Emit[Msg],
  dialog~ : Html,
  toaster~ : Html,
  panes~ : Html,
) -> Html {
  @rui.theme(
    mode=color_mode(model.theme),
    id="tuzi",
    style=[
      ..default_font_theme.style(),
      ..appearance_style,
      "height: 100%",
      "display: flex",
      "flex-direction: column",
    ],
    [
      div(
        style=application_style(),
        [
          ..match model.startup {
            Starting => [@rui.field_description("Connecting to server…")]
            StartupFailed(error) =>
              [
                @rui.field_error(error),
                @rui.button(
                  style=[UI_FONT_STYLE],
                  variant=Outline,
                  on_click=emit(BaseRetry),
                  "Retry connection",
                ),
              ]
            Started => {
              let filter = model.entry_filter()
              let data = (
                model.panes.0.current.view_data(filter?),
                model.panes.1.current.view_data(filter?),
              )
              [model.toolbar_view(data, emit), panes]
            }
          },
          dialog,
        ],
      ),
      toaster,
    ],
  )
}

///|
fn color_mode(theme : Theme) -> @rui.ColorMode {
  match theme {
    Light => Light
    Dark => Dark
  }
}
