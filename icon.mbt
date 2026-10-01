///|
let folder_icons : Map[String, String] = {
  "moon.mod": svg_moonbit_project,
  "moon.work": svg_moonbit_project,
  "Cargo.toml": svg_rust_project,
  "package.json": svg_node_project,
  ".git": svg_git_repository,
}

///|
pub let folder_markers : Array[String] = folder_icons.keys().to_array()

///|
/// Each registered filename or extension owns its SVG content. Empty values
/// are intentional registrations, not requests to use unknown_file.
/// Fill values with trusted complete <svg>...</svg> markup using a viewBox,
/// width="1em", height="1em", and currentColor. Never embed external input.
let builtin_svg_icons : IconRegistry = {
  folder: svg_folder,
  folder_icons,
  dot_folder: svg_dot_folder,
  exact_folder: { ".git": folder_icon_with(fill="#f14e3288") },
  unknown_file: svg_unknown,
  filenames: {
    "moon.mod": svg_moonbit,
    "moon.pkg": svg_moonbit,
    "moon.work": svg_moonbit,
    ".gitignore": svg_file_git,
    ".gitattributes": svg_file_git,
    ".ds_store": SVG_DO_NOT_THROW_RUBBISH,
    "readme.md": file_icon("md ", fill="#408a71"),
  },
  extensions: {
    "pdf": file_icon("pdf", fill="#db5448"),
    "csv": file_icon("csv", fill="#006f38"),
    "toml": file_icon("toml", fill="#dd6b20"),
    "nu": file_icon("nu", fill="#3dd68c"),
    "html": file_icon("html", fill="#e34c26"),
    "js": file_icon("js", fill="#e5d467"),
    "ts": file_icon("ts", fill="#3178c6"),
    "java": file_icon("java", fill="#c22227"),
    "hs": file_icon("hs", fill="#8f4e8b"),
    "wasm": file_icon("wa", fill="#7665d7"),
  },
  rules: [
    svg_rule_text,
    matches(formats_moonbit, svg_moonbit),
    svg_rule_archive,
    matches(formats_image, SVG_IMAGE),
    matches(formats_video, SVG_VIDEO),
    matches(formats_font, SVG_FONT),
    svg_rule_shell,
  ],
}

///|
let matches : (ReadOnlyArray[String], String) -> (String) -> String? = (
  formats,
  content,
) => {
  let extensions = Set::from_iter(formats.iter())
  extension => {
    guard extensions.contains(extension) else { None }
    Some(content)
  }
}
