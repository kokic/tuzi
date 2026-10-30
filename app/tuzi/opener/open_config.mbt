///|
let text_association : @shared.OpenAssociation = {
  openers: ["browser", "vscode", "explorer"],
  default_opener: "browser",
}

///|
let text_preview_association : @shared.OpenAssociation = {
  openers: ["text", "browser", "vscode", "explorer"],
  default_opener: "text",
}

///|
let markdown_association : @shared.OpenAssociation = {
  openers: ["markdown", "browser", "vscode", "explorer"],
  default_opener: "markdown",
}

///|
let session_association : @shared.OpenAssociation = {
  openers: ["session", "text", "browser", "vscode", "explorer"],
  default_opener: "session",
}

///|
let font_association : @shared.OpenAssociation = {
  openers: ["font", "browser", "explorer"],
  default_opener: "font",
}

///|
let image_association : @shared.OpenAssociation = {
  openers: ["image", "browser", "explorer"],
  default_opener: "image",
}

///|
fn configured_openers() -> Map[String, OpenDefinition] {
  {
    "browse": { label: "Enter in Tuzi", execution: Browse, },
    "browser": { label: "Open in browser", execution: Browser, },
    "markdown": { label: "Preview Markdown", execution: Dialog(Markdown), },
    "text": { label: "Preview text", execution: Dialog(Text), },
    "session": { label: "Preview session", execution: Dialog(Session), },
    "font": { label: "Preview font", execution: Dialog(Font), },
    "image": { label: "Preview image", execution: Dialog(Image), },
    "extract": { label: "Extract ZIP", execution: ExtractZip, },
    "vscode": {
      label: "Open in VSCode",
      execution: External(vscode_command()),
    },
    "explorer": {
      label: "Open in system file manager",
      execution: FileManager(system_open_command(Directory)),
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
    },
    extensions: {
      "c": text_association,
      "h": text_association,
      "cpp": text_association,
      "hpp": text_association,
      "md": markdown_association,
      "markdown": {
        openers: ["markdown", "browser", "explorer"],
        default_opener: "markdown",
      },
      "mbt": text_association,
      "mbti": text_association,
      "txt": text_preview_association,
      "rs": text_association,
      "go": text_association,
      "py": text_association,
      "js": text_association,
      "mjs": text_association,
      "ts": text_association,
      "tsx": text_association,
      "jsx": text_association,
      "json": text_preview_association,
      "jsonl": session_association,
      "html": text_association,
      "htm": text_association,
      "css": text_association,
      "xml": text_association,
      "toml": text_preview_association,
      "yaml": text_preview_association,
      "yml": text_preview_association,
      "ini": text_preview_association,
      "conf": text_preview_association,
      "sh": text_association,
      "ttf": font_association,
      "otf": font_association,
      "woff": font_association,
      "woff2": font_association,
      "jpg": image_association,
      "jpeg": image_association,
      "jpe": image_association,
      "jfif": image_association,
      "pjpeg": image_association,
      "pjp": image_association,
      "png": image_association,
      "apng": image_association,
      "gif": image_association,
      "webp": image_association,
      "avif": image_association,
      "bmp": image_association,
      "ico": image_association,
      "cur": image_association,
      "svg": image_association,
      "svgz": image_association,
      "tif": image_association,
      "tiff": image_association,
      "heic": image_association,
      "heif": image_association,
      "jxl": image_association,
      "apk": {
        openers: ["extract", "browser", "explorer"],
        default_opener: "extract",
      },
      "zip": {
        openers: ["extract", "browser", "explorer"],
        default_opener: "extract",
      },
    },
    other_file: { openers: ["browser", "explorer"], default_opener: "browser", },
  }
}
