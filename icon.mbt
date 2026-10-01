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
    ".gitmodules": svg_file_git,
    ".gitkeep": svg_file_git,
    ".gitconfig": svg_file_git,
    ".ds_store": SVG_DO_NOT_THROW_RUBBISH,
    "readme.md": file_icon("md ", fill="#408a71"),
    "readme": file_icon("txt", fill="#408a71"),
    "license": file_icon("lic", fill="#888888"),
    "licence": file_icon("lic", fill="#888888"),
    "copying": file_icon("lic", fill="#888888"),
    "notice": file_icon("txt", fill="#888888"),
    "changelog": file_icon("log", fill="#888888"),
    "makefile": file_icon("mk", fill="#dd6b20"),
    "gnumakefile": file_icon("mk", fill="#dd6b20"),
    "cmakelists.txt": file_icon("cmk", fill="#dd6b20"),
    "dockerfile": file_icon("dock", fill="#2496ed"),
    "containerfile": file_icon("dock", fill="#2496ed"),
    ".dockerignore": file_icon("dock", fill="#2496ed"),
    ".env": file_icon("env", fill="#dd6b20"),
    ".env.local": file_icon("env", fill="#dd6b20"),
    ".env.example": file_icon("env", fill="#dd6b20"),
    ".env.development": file_icon("env", fill="#dd6b20"),
    ".env.production": file_icon("env", fill="#dd6b20"),
    ".env.test": file_icon("env", fill="#dd6b20"),
    ".editorconfig": file_icon("cfg", fill="#dd6b20"),
    ".npmrc": file_icon("npm", fill="#cb3837"),
    ".nvmrc": file_icon("node", fill="#68a063"),
    ".yarnrc": file_icon("yarn", fill="#2c8ebb"),
    ".prettierrc": file_icon("cfg", fill="#dd6b20"),
    ".eslintrc": file_icon("cfg", fill="#dd6b20"),
    ".bashrc": file_icon(".sh", fill="currentColor"),
    ".bash_profile": file_icon(".sh", fill="currentColor"),
    ".zshrc": file_icon(".sh", fill="currentColor"),
    ".zprofile": file_icon(".sh", fill="currentColor"),
    ".profile": file_icon(".sh", fill="currentColor"),
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
    extension => config_icons.get(extension),
    extension => data_icons.get(extension),
    extension => source_icons.get(extension),
    extension => document_icons.get(extension),
    extension => audio_icons.get(extension),
    extension => binary_icons.get(extension),
    extension => text_icons.get(extension),
    matches(formats_moonbit, svg_moonbit),
    extension => archive_icons.get(extension),
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
