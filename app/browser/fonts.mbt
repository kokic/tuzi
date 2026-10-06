///|
priv struct FontSizes {
  entry_title : String
  entry_subtitle : String
  pane_header : String
  footer : String
}

///|
priv struct FontTheme {
  ui_family : String
  code_family : String
  sizes : FontSizes
  entry_line_height : Double
}

///|
let default_font_theme : FontTheme = {
  ui_family: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  code_family: "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
  entry_line_height: 1.25,
  sizes: {
    entry_title: "1rem",
    entry_subtitle: "0.8rem",
    pane_header: "0.8125rem",
    footer: "0.8rem",
  },
}

///|
const UI_FONT_STYLE : String = @presentation.UI_FONT_STYLE

///|
const CODE_FONT_STYLE : String = @presentation.CODE_FONT_STYLE

///|
/// Set typography once on the theme root. Rui controls must also receive
/// UI_FONT_STYLE because their own inline font family overrides inheritance.
fn FontTheme::style(fonts : FontTheme) -> Array[String] {
  [
    "--tuzi-font-ui: \{fonts.ui_family}",
    "--tuzi-font-code: \{fonts.code_family}",
    "--tuzi-entry-title-size: \{fonts.sizes.entry_title}",
    "--tuzi-entry-subtitle-size: \{fonts.sizes.entry_subtitle}",
    "--tuzi-pane-header-size: \{fonts.sizes.pane_header}",
    "--tuzi-footer-size: \{fonts.sizes.footer}",
    "--tuzi-entry-line-height: \{fonts.entry_line_height}",
    UI_FONT_STYLE,
  ]
}
