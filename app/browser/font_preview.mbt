///|
priv enum FontPreviewState {
  Loading
  Loaded(Result[Unit, String])
} derive(Eq)

///|
priv struct FontPreview {
  state : FontPreviewState
  text : String
} derive(Eq)

///|
fn FontPreview::initialize() -> FontPreview {
  {
    state: Loading,
    text: "天地玄黄，宇宙洪荒。\nThe quick brown fox jumps over the lazy dog.\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789 !?.,:;()[]{}",
  }
}

///|
fn InfoContext::font_family(context : InfoContext) -> String {
  "tuzi-font-preview-\{context.id}"
}

///|
priv suberror FontPreviewSubscription {
  Load(String, String, (Result[Unit, String]) -> Cmd)
}

///|
let font_preview_subscription_loader : @sub.SubLoader = @sub.SubLoader((
  payload,
  scheduler,
) => {
  guard payload is FontPreviewSubscription::Load(family, url, callback) else {
    return None
  }
  let handler = Ref(callback)
  let cleanup = load_preview_font(
    family,
    url,
    () => scheduler.add((handler.val)(Ok(()))),
    error => scheduler.add((handler.val)(Err(error))),
  )
  Some({
    unload: _ => cleanup(),
    update_tagger: payload => {
      guard payload is FontPreviewSubscription::Load(_, _, callback) else {
        return
      }
      handler.val = callback
    },
  })
})

///|
fn Model::font_preview_subscription(
  model : Model,
  emit : Emit[Msg],
) -> @sub.Sub {
  guard model.dialog is Info(context) && context.font_preview is Some(_) else {
    return @sub.none
  }
  @sub.custom_sub(
    context.font_family(),
    Local,
    FontPreviewSubscription::Load(
      context.font_family(),
      context.path.file_url(),
      result => emit(FontPreviewLoaded(context.id, result)),
    ),
    font_preview_subscription_loader,
  )
}

///|
fn load_preview_font(
  family : String,
  url : String,
  on_loaded : () -> Unit,
  on_error : (String) -> Unit,
) -> () -> Unit {
  let active = Ref(true)
  let faces : Array[@js.Value] = []
  let promise : @js.Value = @js.globalThis.get_with_string("Promise")
  let ready : @js.Value = promise.apply_with_string(
    "resolve",
    ([] : FixedArray[@js.Value]),
  )
  let loading : @js.Value = ready.apply_with_string("then", [
    (_ : @js.Value) => {
      guard active.val else { return @js.Value::cast_from(()) }
      let sources = [
        (family, url),
        ("\{family}-notdef", "/fonts/AND-Regular.woff2"),
      ]
      let pending : Array[@js.Value] = sources.map(source => {
        let (family, url) = source
        let json : @js.Value = @js.globalThis.get_with_string("JSON")
        let source : String = json.apply_with_string("stringify", [url])
        let face : @js.Value = @js.globalThis.new_with_string("FontFace", [
          family,
          "url(\{source})",
        ])
        faces.push(face)
        face.apply_with_string("load", ([] : FixedArray[@js.Value]))
      })
      promise.apply_with_string("all", [pending])
    },
  ])
  let loaded : @js.Value = loading.apply_with_string("then", [
    (_ : @js.Value) => {
      guard active.val else { return }
      let fonts : @js.Value = @dom.Document::from(@dom.document()).get_with_string(
        "fonts",
      )
      faces.each(face => {
        let _ : @js.Value = fonts.apply_with_string("add", [face])
      })
      on_loaded()
    },
  ])
  let _ : @js.Value = loaded.apply_with_string("catch", [
    (error : @js.Value) => {
      if active.val {
        let message : String = @js.globalThis.apply_with_string("String", [
          error,
        ])
        on_error(message)
      }
    },
  ])
  () => {
    active.val = false
    faces.each(face => {
      let fonts : @js.Value = @dom.Document::from(@dom.document()).get_with_string(
        "fonts",
      )
      let _ : Bool = fonts.apply_with_string("delete", [face])
    })
  }
}

///|
fn Model::receive_font_preview(
  model : Model,
  id : Int32,
  result : Result[Unit, String],
) -> Model {
  guard model.dialog is Info(context) &&
    context.id == id &&
    context.font_preview is Some(preview) &&
    preview.state is Loading else {
    return model
  }
  {
    ..model,
    dialog: Info({
      ..context,
      font_preview: Some({ ..preview, state: Loaded(result), }),
    }),
  }
}

///|
fn Model::with_font_preview_text(model : Model, text : String) -> Model {
  guard model.dialog is Info(context) && context.font_preview is Some(preview) else {
    return model
  }
  {
    ..model,
    dialog: Info({ ..context, font_preview: Some({ ..preview, text, }), }),
  }
}

///|
fn InfoContext::font_preview_view(
  context : InfoContext,
  preview : FontPreview,
  emit : Emit[Msg],
) -> Html {
  let input_id = "font-preview-text-\{context.id}"
  div(
    style=["margin-bottom: 12px"],
    match preview.state {
      Loading => centered_loading_view("Loading font…")
      Loaded(Err(error)) =>
        @rui.alert(variant=Destructive, [
          @rui.alert_title("Unable to load font"),
          @rui.alert_description(error),
        ])
      Loaded(Ok(_)) =>
        div([
          @rui.field([
            @rui.field_label(
              for_=input_id,
              style=[UI_FONT_STYLE],
              "Preview text",
            ),
            @rui.textarea(
              id=input_id,
              value=preview.text,
              rows=5,
              placeholder="Type text to preview this font…",
              on_input=emit.map(text => FontPreviewInput(text)),
              style=[
                "font-family: '\{context.font_family()}', '\{context.font_family()}-notdef'",
                "font-size: 28px",
                "font-weight: normal",
                "font-style: normal",
                "font-synthesis: none",
                "line-height: 1.6",
                "white-space: pre-wrap",
                "max-height: 45dvh",
                "overflow-y: auto",
              ],
            ),
          ]),
          p(
            style=[
              "margin: 12px 0 0", "font-size: 0.8125rem", "color: var(--rui-muted-foreground)",
            ],
            "Crossed boxes indicate characters missing from this font.",
          ),
        ])
    },
  )
}
