// Brand colors: https://github.com/simple-icons/simple-icons/blob/develop/data/simple-icons.json
// Java and C#: https://github.com/devicons/devicon/blob/master/devicon.json
// Multicolor marks use one representative color; monochrome marks use currentColor.

///|
let config_icons : ReadOnlyArray[(String, String)] = [
  ("toml", file_icon("toml", fill="#9c4121")),
  ("json", file_icon("json", fill="currentColor")),
  ("jsonc", file_icon("json", fill="currentColor")),
  ("json5", file_icon("json", fill="currentColor")),
  ("yaml", file_icon("yml", fill="#cb171e")),
  ("yml", file_icon("yml", fill="#cb171e")),
  ("xml", file_icon("xml", fill="#dd6b20")),
  ("ini", file_icon("ini", fill="#dd6b20")),
  ("conf", file_icon("conf", fill="#dd6b20")),
  ("cfg", file_icon("cfg", fill="#dd6b20")),
  ("env", file_icon("env", fill="#dd6b20")),
  ("properties", file_icon("prop", fill="#dd6b20")),
  ("plist", file_icon("plist", fill="#dd6b20")),
  ("lock", file_icon("lock", fill="#dd6b20")),
  ("mk", file_icon("mk", fill="#dd6b20")),
  ("cmake", file_icon("cmk", fill="#064f8c")),
  ("map", file_icon("map", fill="#dd6b20")),
]

///|
let data_icons : ReadOnlyArray[(String, String)] = [
  ("csv", file_icon("csv", fill="#006f38")),
  ("tsv", file_icon("tsv", fill="#006f38")),
  ("sql", file_icon("sql", fill="#006f38")),
  ("db", file_icon("db", fill="#006f38")),
  ("sqlite", file_icon("sql", fill="#003b57")),
  ("sqlite3", file_icon("sql", fill="#003b57")),
  ("jsonl", file_icon("jsonl", fill="currentColor")),
  ("ndjson", file_icon("jsonl", fill="currentColor")),
  ("parquet", file_icon("parq", fill="#006f38")),
]

///|
let source_icons : ReadOnlyArray[(String, String)] = [
  ("nix", file_icon("nix", fill="#5277c3")),
  ("nu", file_icon("nu", fill="#4e9a06")),
  ("html", file_icon("html", fill="#e34f26")),
  ("js", file_icon("js", fill="#f7df1e")),
  ("ts", file_icon("ts", fill="#3178c6")),
  ("java", file_icon("java", fill="#ea2d2e")),
  ("hs", file_icon("hs", fill="#5d4f85")),
  ("htm", file_icon("html", fill="#e34f26")),
  ("css", file_icon("css", fill="#663399")),
  ("scss", file_icon("scss", fill="#cc6699")),
  ("sass", file_icon("sass", fill="#cc6699")),
  ("less", file_icon("less", fill="#1d365d")),
  ("jsx", file_icon("jsx", fill="#61dafb")),
  ("tsx", file_icon("tsx", fill="#61dafb")),
  ("mjs", file_icon("mjs", fill="#f7df1e")),
  ("cjs", file_icon("cjs", fill="#f7df1e")),
  ("cts", file_icon("cts", fill="#3178c6")),
  ("vue", file_icon("vue", fill="#4fc08d")),
  ("svelte", file_icon("svel", fill="#ff3e00")),
  ("py", file_icon("py", fill="#3776ab")),
  ("pyi", file_icon("pyi", fill="#3776ab")),
  ("ipynb", file_icon("jup", fill="#f37626")),
  ("rs", file_icon("rs", fill="currentColor")),
  ("go", file_icon("go", fill="#00add8")),
  ("c", file_icon("c", fill="#a8b9cc")),
  ("h", file_icon("h", fill="#a8b9cc")),
  ("cpp", file_icon("cpp", fill="#00599c")),
  ("cc", file_icon("cc", fill="#00599c")),
  ("cxx", file_icon("cxx", fill="#00599c")),
  ("hpp", file_icon("hpp", fill="#00599c")),
  ("hxx", file_icon("hxx", fill="#00599c")),
  ("cs", file_icon("cs", fill="#68217a")),
  ("rb", file_icon("rb", fill="#cc342d")),
  ("php", file_icon("php", fill="#777bb4")),
  ("swift", file_icon("swft", fill="#f05138")),
  ("kt", file_icon("kt", fill="#7f52ff")),
  ("kts", file_icon("kts", fill="#7f52ff")),
  ("lua", file_icon("lua", fill="#000080")),
  ("dart", file_icon("dart", fill="#0175c2")),
  ("r", file_icon("r", fill="#276dc3")),
  ("jl", file_icon("jl", fill="#9558b2")),
  ("scala", file_icon("scal", fill="#dc322f")),
  ("ex", file_icon("ex", fill="#4b275f")),
  ("exs", file_icon("exs", fill="#4b275f")),
  ("erl", file_icon("erl", fill="#a90533")),
  ("clj", file_icon("clj", fill="#5881d8")),
  ("pl", file_icon("pl", fill="#0073a1")),
  ("ml", file_icon("ml", fill="#ec6813")),
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
  ("wasm", file_icon("wa", fill="#654ff0")),
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
    ("mdx", file_icon("mdx", fill="currentColor")),
    ("txt", file_icon("txt", fill="#888888")),
    ("text", file_icon("txt", fill="#888888")),
    ("log", file_icon("log", fill="#888888")),
    ("srt", file_icon("srt", fill="#888888")),
    ("vtt", file_icon("vtt", fill="#888888")),
    ("rst", file_icon("rst", fill="#888888")),
    ("org", file_icon("org", fill="#77aa99")),
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
