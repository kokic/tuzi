///|
priv enum MarkdownView {
  Preview
  Code
} derive(Eq)

///|
priv enum MarkdownContent {
  Loading
  Loaded(Result[String, String])
} derive(Eq)

///|
priv struct MarkdownContext {
  id : Int
  path : Path
  view : MarkdownView
  content : MarkdownContent
} derive(Eq)

///|
priv enum MarkdownMsg {
  Loaded(Int, Result[String, String])
  ViewChanged(MarkdownView)
}

///|
fn Model::open_markdown(
  model : Model,
  path : Path,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let id = model.dialog_revision + 1
  (
    {
      ..model,
      dialog: Markdown({ id, path, view: Preview, content: Loading, }),
      dialog_error: "",
    },
    @rabbita.perform(result => emit(MarkdownEvent(Loaded(id, result))), () => {
      try {
        let (response, data) = @http.get(
          @dom.window().origin() + path.file_url(),
        )
        guard response.code is (200..<300) else {
          return Err("HTTP \{response.code} \{response.reason}")
        }
        Ok(data.text())
      } catch {
        error => Err(error.to_string())
      }
    }),
  )
}

///|
fn Model::update_markdown(model : Model, msg : MarkdownMsg) -> Model {
  guard model.dialog is Markdown(context) else { return model }
  let context = match msg {
    Loaded(id, result) => {
      // A closed or replaced preview cannot receive an earlier file's response.
      guard id == context.id else { return model }
      { ..context, content: Loaded(result), }
    }
    ViewChanged(view) => { ..context, view, }
  }
  { ..model, dialog: Markdown(context), }
}

///|
fn MarkdownView::label(self : MarkdownView) -> String {
  match self {
    Preview => "Preview"
    Code => "Code"
  }
}

///|
fn MarkdownView::icon(self : MarkdownView) -> Html {
  span(
    style=["display: inline-flex", "flex-shrink: 0"],
    attrs=@html.Attrs::build().aria_hidden("true"),
    @svg.svg(
      width=14,
      height=14,
      view_box="0 0 24 24",
      style=[
        "fill: none", "stroke: currentColor", "stroke-width: 1.8", "stroke-linecap: round",
        "stroke-linejoin: round",
      ],
      match self {
        Preview =>
          [
            @svg.path(d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"),
            @svg.circle(cx=12, cy=12, r=3),
          ]
        Code => [@svg.path(d="m8 5-7 7 7 7m8-14 7 7-7 7m-3-17-2 20")]
      },
    ),
  )
}

///|
fn MarkdownContext::dialog(context : MarkdownContext, emit : Emit[Msg]) -> Html {
  modal(
    context.path.basename(),
    emit,
    style=[
      "width: 960px", "max-width: calc(100vw - 32px)", "height: min(780px, calc(100dvh - 32px))",
      "max-height: calc(100dvh - 32px)", "display: flex", "flex-direction: column",
      "overflow: hidden",
    ],
    [
      @rui.tabs_root(
        value=context.view.label(),
        style=["flex: 1", "min-height: 0"],
        [
          @rui.tabs_list(
            aria_label="Markdown view",
            style=["flex-shrink: 0", "min-height: 0", "padding: 2px"],
            [Preview, Code].map(view => {
              let label = view.label()
              @rui.tabs_trigger(
                value=label,
                id="markdown-tab-\{label}",
                controls="markdown-panel-\{label}",
                selected=context.view == view,
                on_value_change=emit.map(_ => MarkdownEvent(ViewChanged(view))),
                style=[
                  UI_FONT_STYLE,
                  "box-sizing: border-box",
                  "height: 26px",
                  "min-height: 0",
                  "padding: 0 8px",
                  "gap: 4px",
                  "font-size: 0.75rem",
                  "line-height: 18px",
                ],
                [view.icon(), span(label)],
              )
            }),
          ),
          @rui.tabs_content(
            value=context.view.label(),
            id="markdown-panel-\{context.view.label()}",
            labelledby="markdown-tab-\{context.view.label()}",
            selected=true,
            style=[
              "min-height: 0", "overflow: auto", "overscroll-behavior: contain",
              "padding: 12px", "border: 1px solid var(--rui-border)", "user-select: text",
              "overflow-wrap: anywhere",
            ],
            [context.content_view()],
          ),
        ],
      ),
      dialog_close_footer_view(),
    ],
  )
}

///|
fn MarkdownContext::content_view(context : MarkdownContext) -> Html {
  match context.content {
    Loading =>
      div(
        style=["display: flex", "align-items: center", "gap: 8px"],
        attrs=@html.Attrs::build().role("status"),
        [@rui.spinner(label="Loading Markdown"), span("Loading Markdown…")],
      )
    Loaded(Err(error)) => @rui.field_error(error)
    Loaded(Ok(source)) =>
      match context.view {
        Preview => @markdown.markdown(source, escape_link=true)
        Code =>
          @html.pre(
            style=[
              CODE_FONT_STYLE,
              "margin: 0",
              "white-space: pre-wrap",
              "overflow-wrap: anywhere",
              "font-size: 0.8125rem",
              "line-height: 1.6",
            ],
            [@html.code(style=["font-family: inherit"], source)],
          )
      }
  }
}
