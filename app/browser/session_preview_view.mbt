///|
fn session_preview_dialog(model : Val[Model], emit : Emit[Msg]) -> Val[Html] {
  model
  .map(model => {
    match model.dialog {
      SessionPreview(context) => Some(context)
      _ => None
    }
  })
  .switch_by(
    context => {
      guard context is Some(context) else {
        return Val::constant(@html.nothing)
      }
      let content = match context.content {
        Loading => Val::constant(centered_loading_view("Loading session…"))
        Loaded(Err(error)) =>
          Val::constant(
            @rui.alert(variant=Destructive, [
              @rui.alert_title("Unable to preview session"),
              @rui.alert_description(error),
            ]),
          )
        Loaded(Ok(document)) => session_scroller_view(context.id, document)
      }
      content.view(content => {
        modal(
          context.path.basename(),
          emit,
          size=Reading,
          style=[
            "height: min(780px, calc(100dvh - 32px))", "max-height: calc(100dvh - 32px)",
            "display: flex", "flex-direction: column", "overflow: hidden",
          ],
          [
            ..if context.content is Loaded(Ok(document)) &&
              !document.diagnostics.is_empty() {
              [
                @rui.alert(variant=Destructive, [
                  @rui.alert_title(
                    "\{document.diagnostics.length()} record issue(s)",
                  ),
                  @rui.alert_description(
                    "The readable history is shown. Jump to Top for line error details.",
                  ),
                ]),
              ]
            },
            div(
              style=[
                "flex: 1", "min-height: 0", "display: flex", "flex-direction: column",
              ],
              content,
            ),
            dialog_close_footer_view(),
          ],
        )
      })
    },
    by=context => {
      match context {
        None => "closed"
        Some({ id, content: Loading, .. }) => "\{id}-loading"
        Some({ id, content: Loaded(_), .. }) => "\{id}-loaded"
      }
    },
  )
}

///|
fn session_scroller_view(id : Int32, document : @session.Document) -> Val[Html] {
  let rows : Map[String, Html] = Map([])
  rows["header"] = session_header_view(document)
  if !document.diagnostics.is_empty() {
    rows["diagnostics"] = session_diagnostics_view(document.diagnostics)
  }
  if document.entries.is_empty() {
    rows["empty"] = @rui.empty(
      @rui.empty_header([
        @rui.empty_title("No readable records"),
        @rui.empty_description(
          "No history could be loaded after the session header.",
        ),
      ]),
    )
  }
  for index, entry in document.entries {
    rows["line-\{entry.line}"] = @rui.message_scroller_item(
      id="session-\{id}-line-\{entry.line}",
      scroll_anchor=index == document.entries.length() - 1,
      session_entry_view(entry),
    )
  }
  let content = @rui.message_scroller_content(
    style=[
      "gap: 1.25rem", "max-width: 76ch", "margin-inline: auto", "padding-bottom: 3rem",
    ],
    rows,
  )
  @rui.message_scroller(
    id="session-\{id}",
    style=[
      UI_FONT_STYLE,
      "border: 1px solid var(--rui-border)",
      "user-select: text",
    ],
    scope => {
      [
        @rui.message_scroller_viewport(
          scope~,
          attrs=@html.Attrs::build().aria_label("Session history"),
          style=["padding: 16px", "overflow-wrap: anywhere"],
          content,
        ),
        @rui.message_scroller_button(
          scope~,
          direction=ScrollStart,
          size=Sm,
          label="Jump to first record",
          style=[UI_FONT_STYLE],
          "Top",
        ),
        @rui.message_scroller_button(
          scope~,
          direction=ScrollEnd,
          size=Sm,
          label="Jump to latest record",
          style=[UI_FONT_STYLE],
          "Latest",
        ),
      ]
    },
  )
}

///|
fn session_header_view(document : @session.Document) -> Html {
  let agent = match document.agent {
    Pi => "pi"
  }
  div(
    style=["display: flex", "flex-direction: column", "gap: 8px"],
    [
      div(
        style=[
          "display: flex", "align-items: center", "gap: 8px", "flex-wrap: wrap",
        ],
        [
          badge(variant=Secondary, "\{agent} v\{document.version}"),
          span(
            style=["font-size: 0.8125rem", "color: var(--rui-muted-foreground)"],
            "\{document.entries.length()} records",
          ),
        ],
      ),
      p(
        style=[
          "margin: 0", "font-size: 0.8125rem", "color: var(--rui-muted-foreground)",
        ],
        "Full history in file order, including branches. Snapshot taken when opened.",
      ),
      ..if document.cwd is Some(cwd) {
        [p(style=["margin: 0", CODE_FONT_STYLE, "font-size: 0.75rem"], cwd)]
      },
      session_disclosure(
        "Session metadata",
        session_code_view(document.header.stringify(indent=2)),
      ),
    ],
  )
}

///|
fn session_diagnostics_view(diagnostics : Array[@session.Diagnostic]) -> Html {
  @rui.alert(variant=Destructive, [
    @rui.alert_title("\{diagnostics.length()} record issue(s)"),
    @rui.alert_description([
      p(
        "Some records could not be read completely. The remaining history is shown.",
      ),
      session_disclosure(
        "Show line errors",
        div(
          style=["display: flex", "flex-direction: column", "gap: 12px"],
          diagnostics.map(issue => {
            div([
              p(
                style=["margin: 0", "font-weight: 600"],
                "Line \{issue.line}: \{issue.message}",
              ),
              session_code_view(issue.source),
            ])
          }),
        ),
      ),
    ]),
  ])
}
