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
            Starting => [@rui.spinner(label="Connecting to server…")]
            StartupFailed(error) =>
              [
                @rui.empty(attrs=@html.Attrs::build().role("alert"), [
                  @rui.empty_header([
                    @rui.empty_title("Unable to connect to server"),
                    @rui.empty_description(error),
                  ]),
                  @rui.empty_content(
                    @rui.button(
                      variant=Outline,
                      on_click=emit(BaseRetry),
                      "Retry connection",
                    ),
                  ),
                ]),
              ]
            Started => {
              let data = (
                model.panes.0.current.view_data(
                  filter?=model.entry_filter(Left),
                ),
                model.panes.1.current.view_data(
                  filter?=model.entry_filter(Right),
                ),
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
