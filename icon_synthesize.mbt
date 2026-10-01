///|
let config_icons : ReadOnlyArray[(String, String)] = [
  ("toml", file_icon("toml", fill="#dd6b20")),
  ("json", file_icon("json", fill="#dd6b20")),
  ("jsonc", file_icon("json", fill="#dd6b20")),
  ("json5", file_icon("json", fill="#dd6b20")),
  ("yaml", file_icon("yml", fill="#dd6b20")),
  ("yml", file_icon("yml", fill="#dd6b20")),
  ("xml", file_icon("xml", fill="#dd6b20")),
  ("ini", file_icon("ini", fill="#dd6b20")),
  ("conf", file_icon("conf", fill="#dd6b20")),
  ("cfg", file_icon("cfg", fill="#dd6b20")),
  ("env", file_icon("env", fill="#dd6b20")),
  ("properties", file_icon("prop", fill="#dd6b20")),
  ("plist", file_icon("plist", fill="#dd6b20")),
  ("lock", file_icon("lock", fill="#dd6b20")),
  ("mk", file_icon("mk", fill="#dd6b20")),
  ("cmake", file_icon("cmk", fill="#dd6b20")),
  ("map", file_icon("map", fill="#dd6b20")),
]

///|
let data_icons : ReadOnlyArray[(String, String)] = [
  ("csv", file_icon("csv", fill="#006f38")),
  ("tsv", file_icon("tsv", fill="#006f38")),
  ("sql", file_icon("sql", fill="#006f38")),
  ("db", file_icon("db", fill="#006f38")),
  ("sqlite", file_icon("sql", fill="#006f38")),
  ("sqlite3", file_icon("sql", fill="#006f38")),
  ("jsonl", file_icon("jsonl", fill="#006f38")),
  ("ndjson", file_icon("jsonl", fill="#006f38")),
  ("parquet", file_icon("parq", fill="#006f38")),
]

///|
let source_icons : ReadOnlyArray[(String, String)] = [
  ("nu", file_icon("nu", fill="#3dd68c")),
  ("html", file_icon("html", fill="#e34c26")),
  ("js", file_icon("js", fill="#e5d467")),
  ("ts", file_icon("ts", fill="#3178c6")),
  ("java", file_icon("java", fill="#c22227")),
  ("hs", file_icon("hs", fill="#8f4e8b")),
  ("htm", file_icon("html", fill="#e34c26")),
  ("css", file_icon("css", fill="#3178c6")),
  ("scss", file_icon("scss", fill="#cc6699")),
  ("sass", file_icon("sass", fill="#cc6699")),
  ("less", file_icon("less", fill="#3178c6")),
  ("jsx", file_icon("jsx", fill="#61afcf")),
  ("tsx", file_icon("tsx", fill="#3178c6")),
  ("mjs", file_icon("mjs", fill="#e5d467")),
  ("cjs", file_icon("cjs", fill="#e5d467")),
  ("cts", file_icon("cts", fill="#3178c6")),
  ("vue", file_icon("vue", fill="#42b883")),
  ("svelte", file_icon("svel", fill="#ff6b3e")),
  ("py", file_icon("py", fill="#3776ab")),
  ("pyi", file_icon("pyi", fill="#3776ab")),
  ("ipynb", file_icon("jup", fill="#e58f35")),
  ("rs", file_icon("rs", fill="#b8754a")),
  ("go", file_icon("go", fill="#00add8")),
  ("c", file_icon("c", fill="#3178c6")),
  ("h", file_icon("h", fill="#3178c6")),
  ("cpp", file_icon("cpp", fill="#3178c6")),
  ("cc", file_icon("cc", fill="#3178c6")),
  ("cxx", file_icon("cxx", fill="#3178c6")),
  ("hpp", file_icon("hpp", fill="#3178c6")),
  ("hxx", file_icon("hxx", fill="#3178c6")),
  ("cs", file_icon("cs", fill="#8f4e8b")),
  ("rb", file_icon("rb", fill="#cc5555")),
  ("php", file_icon("php", fill="#8589c2")),
  ("swift", file_icon("swft", fill="#ef7545")),
  ("kt", file_icon("kt", fill="#a777dd")),
  ("kts", file_icon("kts", fill="#a777dd")),
  ("lua", file_icon("lua", fill="#438f9e")),
  ("dart", file_icon("dart", fill="#438f9e")),
  ("r", file_icon("r", fill="#438f9e")),
  ("jl", file_icon("jl", fill="#438f9e")),
  ("scala", file_icon("scal", fill="#438f9e")),
  ("ex", file_icon("ex", fill="#438f9e")),
  ("exs", file_icon("exs", fill="#438f9e")),
  ("erl", file_icon("erl", fill="#438f9e")),
  ("clj", file_icon("clj", fill="#438f9e")),
  ("pl", file_icon("pl", fill="#438f9e")),
  ("ml", file_icon("ml", fill="#438f9e")),
]

///|
let document_icons : ReadOnlyArray[(String, String)] = [
  ("pdf", file_icon("pdf", fill="#db5448")),
  ("doc", file_icon("doc", fill="#3178c6")),
  ("docx", file_icon("docx", fill="#3178c6")),
  ("odt", file_icon("odt", fill="#3178c6")),
  ("rtf", file_icon("rtf", fill="#3178c6")),
  ("xls", file_icon("xls", fill="#278653")),
  ("xlsx", file_icon("xlsx", fill="#278653")),
  ("xlsm", file_icon("xlsm", fill="#278653")),
  ("ods", file_icon("ods", fill="#278653")),
  ("ppt", file_icon("ppt", fill="#d77545")),
  ("pptx", file_icon("pptx", fill="#d77545")),
  ("odp", file_icon("odp", fill="#d77545")),
  ("pages", file_icon("page", fill="#d77545")),
  ("numbers", file_icon("nums", fill="#278653")),
  ("key", file_icon("key", fill="#3178c6")),
  ("epub", file_icon("epub", fill="#8f4e8b")),
  ("mobi", file_icon("mobi", fill="#8f4e8b")),
]

///|
let binary_icons : ReadOnlyArray[(String, String)] = [
  ("wasm", file_icon("wa", fill="#7665d7")),
  ("exe", file_icon("exe", fill="#cc6666")),
  ("dll", file_icon("dll", fill="#cc6666")),
  ("so", file_icon("so", fill="#cc6666")),
  ("dylib", file_icon("dyl", fill="#cc6666")),
  ("bin", file_icon("bin", fill="#cc6666")),
  ("msi", file_icon("msi", fill="#cc6666")),
  ("appimage", file_icon("app", fill="#cc6666")),
  ("pkg", file_icon("pkg", fill="#c19553")),
  ("dmg", file_icon("dmg", fill="#c19553")),
  ("iso", file_icon("iso", fill="#c19553")),
  ("img", file_icon("img", fill="#c19553")),
]

///|
let text_icons : ReadOnlyArray[(String, String)] = {
  let asciidoc = file_icon("ad", fill="#888888")
  [
    ("md", svg_markdown),
    ("markdown", svg_markdown),
    ("mdx", file_icon("mdx", fill="#888888")),
    ("txt", file_icon("txt", fill="#888888")),
    ("text", file_icon("txt", fill="#888888")),
    ("log", file_icon("log", fill="#888888")),
    ("srt", file_icon("srt", fill="#888888")),
    ("vtt", file_icon("vtt", fill="#888888")),
    ("rst", file_icon("rst", fill="#888888")),
    ("org", file_icon("org", fill="#888888")),
    ("adoc", asciidoc),
    ("asciidoc", asciidoc),
    ("tex", file_icon("tex", fill="#008080")),
    ("ltx", file_icon("ltx", fill="#008080")),
    ("cls", file_icon("cls", fill="#008080")),
    ("sty", file_icon("sty", fill="#008080")),
    ("typ", file_icon("typ", fill="#239dad")),
  ]
}

///|
pub fn file_icon(
  extension : String,
  font_size? : Float = 9.5,
  font_weight? : Int = 400,
  fill? : String = "currentColor",
) -> String {
  file_icon_with(
    extension,
    font_size~,
    font_weight~,
    frame_fill=fill,
    text_fill=fill,
  )
}

///|
/// Labels longer than 3 characters are condensed to fit the icon.
pub fn file_icon_with(
  extension : String,
  font_size? : Float = 9.5,
  font_weight? : Int = 500,
  frame_fill? : String = "currentColor",
  text_fill? : String = "currentColor",
  text_stroke? : String = text_fill,
  font_family? : String = "inherit",
  scale? : Float = 1,
) -> String {
  let length = extension.length()
  let length_attribute = if length <= 3 { "" } else { "textLength=\"18\"" }
  (
    $|<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><g transform="translate(\{((24.0 * (1.0 - scale)) / 2.0 : Float)}) scale(\{scale})"><path d="M4.997875 9V1H19.5L23 4.5V23H4 M18 1V6H23" fill="none" stroke="\{frame_fill}" stroke-width="2" stroke-linejoin="miter"/><text x="11" y="20" text-anchor="middle" fill="\{text_fill}" stroke="\{text_stroke}" stroke-width="0.5" paint-order="stroke fill" font-size="\{font_size}" font-weight="\{font_weight}" font-family="\{font_family}" \{length_attribute} lengthAdjust="spacingAndGlyphs">\{extension}</text></g></svg>
  )
}

///|
pub fn folder_icon_with(
  fill? : String = "currentColor",
  text? : String = "",
  text_fill? : String = "currentColor",
  text_stroke? : String = fill,
  font_family? : String = "inherit",
  font_weight? : Int = 500,
) -> String {
  let length = text.length()
  let length_attribute = if length <= 3 { "" } else { "textLength=\"22\"" }
  (
    $|<svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><path d="M27.5 5.5H18.2L16.1 9.7H4.4V26.5H29.6V5.5Zm0 4.2H19.3l1.1-2.1h7.1Z" fill="\{fill}"/><text x="20" y="26" text-anchor="middle" fill="\{text_fill}" stroke="\{text_stroke}" stroke-width="2" paint-order="stroke fill" font-size="16" font-weight="\{font_weight}" font-family="\{font_family}" \{length_attribute} lengthAdjust="spacingAndGlyphs">\{text}</text></svg>
  )
}

// https://www.svgrepo.com/collection/handdrawn-icons/
// https://www.svgrepo.com/collection/vscode-icons/
