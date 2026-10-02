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
let extension_icons : Map[String, String] = {
  let shell_icon = file_icon(".sh", fill="currentColor")
  Map::from_iter(
    [
      shell_formats
      .iter()
      .map(extension => {
        let icon = match extension {
          "bash" => file_icon(".sh", fill="#4eaa25")
          // https://github.com/PowerShell/PowerShell/blob/master/assets/powershell_128.svg
          "ps1" => file_icon("ps1", fill="#5391fe")
          _ => shell_icon
        }
        (extension, icon)
      }),
      font_formats.iter().map(extension => (extension, SVG_FONT)),
      video_formats.iter().map(extension => (extension, SVG_VIDEO)),
      image_formats.iter().map(extension => (extension, SVG_IMAGE)),
      moonbit_formats.iter().map(extension => (extension, svg_moonbit)),
      audio_formats.iter().map(e => (e, file_icon(e, fill="#c66b9b"))),
      archive_formats
      .iter()
      .map(e => (e, file_icon(e.to_upper(), fill="#c19553"))),
      config_icons.iter(),
      data_icons.iter(),
      source_icons.iter(),
      document_icons.iter(),
      binary_icons.iter(),
      text_icons.iter(),
    ]
    .iter()
    .flatten(),
  )
}

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
    "flake.lock": file_icon("nix", fill="#5277c3"),
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
    "cmakelists.txt": file_icon("cmk", fill="#064f8c"),
    "dockerfile": file_icon("dock", fill="#2496ed"),
    "containerfile": file_icon("dock", fill="#2496ed"),
    ".dockerignore": file_icon("dock", fill="#2496ed"),
    ".env": file_icon("env", fill="#dd6b20"),
    ".env.local": file_icon("env", fill="#dd6b20"),
    ".env.example": file_icon("env", fill="#dd6b20"),
    ".env.development": file_icon("env", fill="#dd6b20"),
    ".env.production": file_icon("env", fill="#dd6b20"),
    ".env.test": file_icon("env", fill="#dd6b20"),
    ".editorconfig": file_icon("cfg", fill="currentColor"),
    ".npmrc": file_icon("npm", fill="#cb3837"),
    ".nvmrc": file_icon("nvm", fill="#f4dd4b"),
    ".yarnrc": file_icon("yarn", fill="#2c8ebb"),
    ".prettierrc": file_icon("cfg", fill="#f7b93e"),
    ".eslintrc": file_icon("cfg", fill="#4b32c3"),
    ".bashrc": file_icon(".sh", fill="#4eaa25"),
    ".bash_profile": file_icon(".sh", fill="#4eaa25"),
    ".zshrc": file_icon(".sh", fill="currentColor"),
    ".zprofile": file_icon(".sh", fill="currentColor"),
    ".profile": file_icon(".sh", fill="currentColor"),
  },
  extensions: extension_icons,
  rules: [],
}
