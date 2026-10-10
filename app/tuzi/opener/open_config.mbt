///|
let text_association : @shared.OpenAssociation = {
  openers: ["preview", "vscode", "explorer"],
  default_opener: "preview",
}

///|
/// Define each application once here; associations below refer to these IDs.
/// Programs and arguments stay on the server and are never accepted from clients.
fn configured_openers() -> Map[String, OpenDefinition] {
  {
    "browse": { label: "Enter in Tuzi", execution: Browse, },
    "preview": { label: "Open in browser", execution: Preview, },
    "extract": { label: "Extract ZIP", execution: ExtractZip, },
    "vscode": {
      label: "Open in VSCode",
      execution: External(vscode_command()),
    },
    "explorer": {
      label: "Open in system file manager",
      execution: External(system_open_command(Directory)),
    },
  }
}

///|
#cfg(platform="windows")
fn vscode_command() -> OpenCommand {
  {
    program: "cmd",
    arguments: [
      Literal("/d"),
      Literal("/c"),
      Literal("code"),
      Literal("--"),
      Target,
    ],
  }
}

///|
#cfg(not(platform="windows"))
fn vscode_command() -> OpenCommand {
  match @async.platform {
    MacOS =>
      {
        program: "/usr/bin/open",
        arguments: [Literal("-a"), Literal("Visual Studio Code"), Target],
      }
    Linux => { program: "code", arguments: [Literal("--"), Target], }
    Windows => panic()
  }
}

///|
/// Complete filenames override extensions. Each association owns its whole menu.
fn configured_open_registry(
  openers : Map[String, @shared.Opener],
) -> @shared.OpenRegistry {
  {
    openers,
    folder: {
      openers: ["browse", "explorer", "vscode"],
      default_opener: "browse",
    },
    filenames: {
      "moon.mod": text_association,
      "moon.pkg": text_association,
      "moon.work": text_association,
      "makefile": text_association,
      "dockerfile": text_association,
      ".gitignore": text_association,
      ".gitattributes": text_association,
      ".env": text_association,
      ".zip": {
        openers: ["extract", "preview", "explorer"],
        default_opener: "extract",
      },
    },
    extensions: {
      "c": text_association,
      "h": text_association,
      "cpp": text_association,
      "hpp": text_association,
      "md": text_association,
      "mbt": text_association,
      "mbti": text_association,
      "txt": text_association,
      "rs": text_association,
      "go": text_association,
      "py": text_association,
      "js": text_association,
      "mjs": text_association,
      "ts": text_association,
      "tsx": text_association,
      "jsx": text_association,
      "json": text_association,
      "html": text_association,
      "htm": text_association,
      "css": text_association,
      "xml": text_association,
      "toml": text_association,
      "yaml": text_association,
      "yml": text_association,
      "ini": text_association,
      "conf": text_association,
      "sh": text_association,
      "zip": {
        openers: ["extract", "preview", "explorer"],
        default_opener: "extract",
      },
    },
    other_file: { openers: ["preview", "explorer"], default_opener: "preview", },
  }
}
