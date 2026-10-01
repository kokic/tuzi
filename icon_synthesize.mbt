///|
pub let svg_rule_text : (String) -> String? = {
  let asciidoc = file_icon("ad", fill="#888888")
  let icons = {
    "md": svg_markdown,
    "txt": file_icon("txt", fill="#888888"),
    "rst": file_icon("rst", fill="#888888"),
    "org": file_icon("org", fill="#888888"),
    "adoc": asciidoc,
    "asciidoc": asciidoc,
    "tex": file_icon("tex", fill="#008080"),
    "ltx": file_icon("ltx", fill="#008080"),
    "cls": file_icon("cls", fill="#008080"),
    "sty": file_icon("sty", fill="#008080"),
    "typ": file_icon("typ", fill="#239dad"),
  }
  extension => icons.get(extension)
}

///|
pub let svg_rule_archive : (String) -> String? = {
  let extensions = [
    "zip", "tar", "gz", "tgz", "bz2", "tbz", "xz", "txz", "lz", "tlz", "lzo", "zst",
    "7z", "rar", "cab", "jar", "war", "ear", "apk", "ipa", "deb", "rpm", "ar", "z",
    "lz4", "br", "ace", "arc", "lha", "lzh", "zoo", "sit", "tbz2", "lzma", "tzst",
    "cpio", "sitx",
  ]
  let icons = Map::from_iter(
    extensions
    .iter()
    .map(extension => {
      (extension, file_icon(extension.to_upper(), fill="#c19553"))
    }),
  )
  extension => icons.get(extension)
}

///|
pub let svg_rule_shell : (String) -> String? = matches(
  ["sh", "bash", "zsh", "fish", "csh", "tcsh", "bat", "cmd", "ps1"],
  file_icon(".sh", fill="currentColor"),
)

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
