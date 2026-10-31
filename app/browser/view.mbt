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
      ..typography_style,
      ..appearance_style,
      ..match model.theme {
        Light => [
          "--rui-background: #fcfcfb", "--rui-card: #fcfcfb", "--rui-popover: #fcfcfb",
          "--rui-outline-background: #fcfcfb",
        ]
        Dark => []
      },
      "height: 100%", "display: flex", "flex-direction: column",
    ],
    [
      div(
        style=application_style(),
        [
          ..match model.startup {
            Starting => [centered_loading_view("Connecting to server…")]
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
            Started => [model.toolbar_view(emit), panes]
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
