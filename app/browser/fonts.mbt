///|
const UI_FONT_STYLE : String = @presentation.UI_FONT_STYLE

///|
const CODE_FONT_STYLE : String = @presentation.CODE_FONT_STYLE

///|
/// Set typography once on the theme root. Rui controls must also receive
/// UI_FONT_STYLE because their own inline font family overrides inheritance.
let typography_style : Array[String] = [
  "--tuzi-font-ui: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  "--tuzi-font-code: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
  "--tuzi-entry-title-size: 1rem",
  "--tuzi-entry-subtitle-size: 0.8rem",
  "--tuzi-pane-header-size: 0.8125rem",
  "--tuzi-footer-size: 0.8rem",
  "--tuzi-entry-line-height: 1.25",
  UI_FONT_STYLE,
]
