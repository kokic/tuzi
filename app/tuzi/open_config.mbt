///|
/// Define each application once here; associations below refer to these IDs.
/// Programs and arguments stay on the server and are never accepted from clients.
async fn configured_openers(platform : OpenPlatform) -> Map[String, OpenDefinition] {
  let vscode : OpenCommand = match platform {
    Windows => {
      program: windows_vscode_program(),
      arguments: [Literal("--"), TargetPath],
    }
    MacOS => {
      program: "/usr/bin/open",
      arguments: [Literal("-a"), Literal("Visual Studio Code"), TargetPath],
    }
    Linux => { program: "code", arguments: [Literal("--"), TargetPath], }
  }
  let explorer : OpenCommand = {
    program: match platform {
      Windows => "explorer.exe"
      MacOS => "/usr/bin/open"
      Linux => "xdg-open"
    },
    arguments: [TargetPath],
  }
  {
    "browse": { label: "Enter in Tuzi", execution: Browse, },
    "preview": { label: "Open in browser", execution: Preview, },
    "extract": { label: "Extract ZIP", execution: ExtractZip, },
    "vscode": { label: "Open in VSCode", execution: External(vscode), },
    "explorer": {
      label: if platform == Windows {
        "Open in Windows Explorer"
      } else {
        "Open in system file manager"
      },
      execution: External(explorer),
    },
  }
}

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
