///|
let folder_colors : Map[String, String] = Map::from_iter(
  @tuzi.folder_marker_kinds
  .iter()
  .map(entry => {
    let (marker, kind) = entry
    let color = match kind {
      MoonBit => "#b84c90bb"
      Rust => "#ef4900"
      Node => "#8ebf55"
      Git => "#808080"
    }
    (marker, color)
  }),
)

///|
let extension_colors : Map[String, String] = Map::from_iter(
  [
    shell_formats
    .iter()
    .map(extension => {
      let color = match extension {
        "bash" => "#4eaa25"
        "ps1" => "#5391fe"
        _ => "currentColor"
      }
      (extension, color)
    }),
    font_formats.iter().map(extension => (extension, "#888888")),
    video_formats.iter().map(extension => (extension, "#fb7299")),
    image_formats.iter().map(extension => (extension, "#49c9a7")),
    moonbit_formats.iter().map(extension => (extension, "#b84c90bb")),
    audio_formats.iter().map(e => (e, "#c66b9b")),
    archive_formats.iter().map(e => (e, "#c19553")),
    config_colors.iter(),
    data_colors.iter(),
    source_colors.iter(),
    document_colors.iter(),
    binary_colors.iter(),
    text_colors.iter(),
  ]
  .iter()
  .flatten(),
)

///|
/// Each registered filename, extension, or folder owns its representative color.
let builtin_entry_colors : EntryColorRegistry = {
  folder: "#dcb67a",
  marker_colors: folder_colors,
  dot_folder: "#d4c5b188",
  exact_folder: { ".git": "#f14e3288" },
  unknown_file: "#888888",
  filenames: {
    "moon.mod": "#b84c90bb",
    "moon.pkg": "#b84c90bb",
    "moon.work": "#b84c90bb",
    "flake.lock": "#5277c3",
    ".gitignore": "#f03c2e",
    ".gitattributes": "#f03c2e",
    ".gitmodules": "#f03c2e",
    ".gitkeep": "#f03c2e",
    ".gitconfig": "#f03c2e",
    ".ds_store": "#ff4b00",
    "readme.md": "#408a71",
    "readme": "#408a71",
    "license": "#888888",
    "licence": "#888888",
    "copying": "#888888",
    "notice": "#888888",
    "changelog": "#888888",
    "makefile": "#dd6b20",
    "gnumakefile": "#dd6b20",
    "cmakelists.txt": "#064f8c",
    "dockerfile": "#2496ed",
    "containerfile": "#2496ed",
    ".dockerignore": "#2496ed",
    ".env": "#dd6b20",
    ".env.local": "#dd6b20",
    ".env.example": "#dd6b20",
    ".env.development": "#dd6b20",
    ".env.production": "#dd6b20",
    ".env.test": "#dd6b20",
    ".editorconfig": "currentColor",
    ".npmrc": "#cb3837",
    ".nvmrc": "#f4dd4b",
    ".yarnrc": "#2c8ebb",
    ".prettierrc": "#f7b93e",
    ".eslintrc": "#4b32c3",
    ".bashrc": "#4eaa25",
    ".bash_profile": "#4eaa25",
    ".zshrc": "currentColor",
    ".zprofile": "currentColor",
    ".profile": "currentColor",
  },
  extensions: extension_colors,
}
