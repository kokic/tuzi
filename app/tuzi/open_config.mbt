///|
/// Define each application once here; associations below refer to these IDs.
/// Programs and arguments stay on the server and are never accepted from clients.
fn configured_openers() -> Map[String, OpenDefinition] {
  {
    "browse": { label: "Enter in Tuzi", execution: Browse, },
    "preview": { label: "Open in browser", execution: Preview, },
    "extract": { label: "Extract ZIP", execution: ExtractZip, },
    "vscode": { label: "Open in VSCode", execution: External(vscode_command()), },
    "explorer": {
      label: file_manager_label,
      execution: External(system_open_command(Directory)),
    },
  }
}

///|
#cfg(platform="windows")
fn vscode_command() -> OpenCommand {
  {
    program: "cmd",
    arguments: [Literal("/d"), Literal("/c"), Literal("code"), Literal("--"), Target],
  }
}

///|
#cfg(platform="macos")
fn vscode_command() -> OpenCommand {
  {
    program: "/usr/bin/open",
    arguments: [Literal("-a"), Literal("Visual Studio Code"), Target],
  }
}

///|
#cfg(platform="linux")
fn vscode_command() -> OpenCommand {
  { program: "code", arguments: [Literal("--"), Target], }
}

///|
#cfg(platform="windows")
let file_manager_label : String = "Open in Windows Explorer"

///|
#cfg(any(platform="macos", platform="linux"))
let file_manager_label : String = "Open in system file manager"

///|
/// Complete filenames override extensions. Each association owns its whole menu.
fn configured_open_registry(openers : Map[String, @shared.Opener]) -> @shared.OpenRegistry {
  let text : @shared.OpenAssociation = {
    openers: ["preview", "vscode"],
    default_opener: "preview",
  }
  let extensions : Map[String, @shared.OpenAssociation] = Map([])
  for extension in [
    "c", "h", "cpp", "hpp", "md", "mbt", "mbti", "txt", "rs", "go", "py",
    "js", "mjs", "ts", "tsx", "jsx", "json", "html", "htm", "css", "xml",
    "toml", "yaml", "yml", "ini", "conf", "sh",
  ] {
    extensions[extension] = text
  }
  extensions["zip"] = {
    openers: ["extract", "preview"],
    default_opener: "extract",
  }
  {
    openers,
    folder: {
      openers: ["browse", "explorer", "vscode"],
      default_opener: "browse",
    },
    filenames: {
      "moon.mod": text,
      "moon.pkg": text,
      "moon.work": text,
      "makefile": text,
      "dockerfile": text,
      ".gitignore": text,
      ".gitattributes": text,
      ".env": text,
      ".zip": { openers: ["extract", "preview"], default_opener: "extract", },
    },
    extensions,
    other_file: { openers: ["preview"], default_opener: "preview", },
  }
}
