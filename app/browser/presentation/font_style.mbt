///|
/// UI and prose use the active theme's UI family.
pub const UI_FONT_STYLE : String = "font-family: var(--tuzi-font-ui)"

///|
/// File names, filter input, text/code and shortcuts use the content family.
pub const CONTENT_FONT_STYLE : String = "font-family: var(--tuzi-font-content)"

///|
/// Task output and error details use the mono family.
pub const MONO_FONT_STYLE : String = "font-family: var(--tuzi-font-mono)"

///|
/// Entry numbers, sizes, timestamps and the file status bar use the metadata family.
const METADATA_FONT_STYLE : String = "font-family: var(--tuzi-font-metadata)"

///|
pub fn theme_font_style(theme : @tuzi.Theme) -> Array[String] {
  match theme {
    Light =>
      [
        "--tuzi-font-ui: Alegreya, ui-serif, serif", "--tuzi-font-content: Alegreya, ui-serif, serif",
        "--tuzi-font-metadata: Alegreya, ui-serif, serif", "--tuzi-ui-size: 0.875rem",
        "--tuzi-content-size: 1rem", "--tuzi-secondary-size: 0.8rem", "--tuzi-caption-size: 0.75rem",
        "--tuzi-code-size: 0.8125rem", "--tuzi-font-preview-size: 28px",
      ]
    Dark =>
      [
        "--tuzi-font-ui: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "--tuzi-font-content: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
        "--tuzi-font-metadata: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
        "--tuzi-ui-size: 0.875rem", "--tuzi-content-size: 1rem", "--tuzi-secondary-size: 0.8rem",
        "--tuzi-caption-size: 0.75rem", "--tuzi-code-size: 0.8125rem", "--tuzi-font-preview-size: 28px",
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
  #|html { font-size: 20px; }
  #|#tuzi {
  #|  --tuzi-font-mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  #|  --tuzi-weight-ui: 400;
  #|  --tuzi-weight-emphasis: 600;
  #|  --tuzi-weight-cursor: 800;
  #|  font-size: var(--tuzi-ui-size);
  #|  font-weight: var(--tuzi-weight-ui);
  #|}
  #|#tuzi :where(button, input, select, textarea) { font-family: inherit; font-size: inherit; }
  #|#tuzi .rui-markdown { font-family: var(--tuzi-font-ui); font-size: calc(var(--tuzi-content-size) * 1.125); }
  #|@media (min-width: 48rem), print { #tuzi .rui-markdown { font-size: var(--tuzi-content-size); } }
  #|#tuzi .rui-markdown h1 { font-size: 1.75em; }
  #|#tuzi .rui-markdown h2 { font-size: 1.25em; }
  #|#tuzi .rui-markdown h3 { font-size: 1.125em; }
  #|#tuzi .rui-markdown h4 { font-size: 1em; }
  #|#tuzi .rui-markdown h5 { font-size: 0.875em; }
  #|#tuzi .rui-markdown h6 { font-size: 0.8125em; }
  #|#tuzi .rui-markdown code { font-family: var(--tuzi-font-content); font-size: 0.85em; }
  #|#tuzi .rui-markdown pre { font-size: 0.875em; }
  #|#tuzi .rui-markdown pre code { font-size: inherit; }
  #|#tuzi .rui-markdown table { font-size: 1em; }
  #|#tuzi .rui-markdown .rui-markdown-footnotes { font-size: 0.875em; }
  #|#tuzi .rui-markdown :where(h1,h2,h3,h4) code { font-size: 0.9em; }
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
