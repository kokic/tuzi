///|
/// UI and prose use the active theme's UI family.
pub const UI_FONT_STYLE : String = "font-family: var(--tuzi-font-ui)"

///|
/// File metadata, code, logs and keyboard shortcuts use the code family.
pub const CODE_FONT_STYLE : String = "font-family: var(--tuzi-font-code)"

///|
/// Each theme supplies its final font families, without component fallbacks.
pub fn theme_font_style(theme : @tuzi.Theme) -> Array[String] {
  match theme {
    Light =>
      [
        "--tuzi-font-ui: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "--tuzi-font-code: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
      ]
    Dark =>
      [
        "--tuzi-font-ui: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "--tuzi-font-code: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
      ]
  }
}

///|
/// Font previews intentionally use the loaded font rather than a theme family.
pub fn preview_font_style(family : String) -> String {
  "font-family: '\{family}', '\{family}-notdef'"
}

///|
const FontCss : String =
  #|#tuzi :where(button, input, select, textarea) { font-family: inherit; }
  #|#tuzi .rui-markdown { font-family: var(--tuzi-font-ui); }
  #|#tuzi .rui-markdown code { font-family: var(--tuzi-font-code); }
  #|#tuzi pre > code { font-family: inherit; }

///|
/// Native controls inherit their component's role; Markdown declares its roles.
#warnings("-alert_xss_vulnerable")
pub fn font_stylesheet() -> @html.Html {
  // Closed CSS constant, never user content.
  @html.style_tag(
    attrs=@html.Attrs::build().inner_html(FontCss),
    ([] : Array[@html.Html]),
  )
}
