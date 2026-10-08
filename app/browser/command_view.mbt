///|
const CommandDialogId : String = "tuzi-command-dialog"

///|
fn global_command_view() -> Val[Html] {
  @rui.command_dialog(
    id=CommandDialogId,
    aria_label="Command",
    style=[UI_FONT_STYLE],
    attrs=@html.Attrs::build().on_keydown(event => {
      // Keep palette input and navigation out of the file-manager shortcuts.
      event.stop_propagation()
      @rabbita.none
    }),
    scope => {
      @html.fragment([
        @rui.command_input(scope~, placeholder="Type a command…", input_style=[
          UI_FONT_STYLE,
        ]),
        @rui.command_list(scope~, [
          @rui.command_empty(scope~, "No matching commands."),
          @rui.command_group(scope~, [
            command_link_item(
              scope~,
              "Contribution: New issue",
              "https://github.com/kokic/tuzi/releases",
            ),
            // Navigation
            command_link_item(
              scope~,
              "Navigation: Compiler Explorer",
              "https://godbolt.org/",
            ),
            command_link_item(
              scope~,
              "Navigation: Excalidraw",
              "https://excalidraw.com/",
            ),
            command_link_item(
              scope~,
              "Navigation: HexEd.it",
              "https://https://hexed.it/",
            ),
            command_link_item(
              scope~,
              "Navigation: KaTeX Supported Functions",
              "https://katex.org/docs/supported.html",
            ),
            command_link_item(
              scope~,
              "Navigation: Try Pandoc!",
              "https://pandoc.org/try/",
            ),
          ]),
        ]),
      ])
    },
  )
}

///|
fn command_link_item(
  scope~ : @rui.CommandScope,
  label : String,
  url : String,
) -> Html {
  @rui.command_item(
    scope~,
    value=label,
    on_click=open_command_url(url),
    style=[UI_FONT_STYLE],
    label,
  )
}

///|
fn open_command_url(url : String) -> Cmd {
  @rabbita.effect(() => {
    let window = @dom.Window::from(@dom.window())
    let opened : @js.Value = window.apply_with_string("open", [
      url, "_blank", "noopener",
    ])
    ignore(opened)
  })
}
