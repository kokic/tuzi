///|
priv enum OpenPlatform {
  Windows
  MacOS
  Linux
} derive(Eq)

///|
/// URL opening and directory browsing have different Windows commands.
priv enum SystemOpenKind {
  Url
  Directory
}

///|
/// Detect once at startup and share the result with all opening methods.
async fn OpenPlatform::detect() -> OpenPlatform {
  guard @path.sep != '\\' else { return Windows }
  let (_, output) = @process.collect_stdout("uname", [])
  if output.text().trim() == "Darwin" { MacOS } else { Linux }
}

///|
fn OpenPlatform::system_open_command(
  self : OpenPlatform,
  kind : SystemOpenKind,
) -> OpenCommand {
  match self {
    Windows =>
      match kind {
        Url => {
          program: "cmd",
          // The empty argument is start's window title, before the URL.
          arguments: [Literal("/c"), Literal("start"), Literal(""), Target],
        }
        Directory => { program: "explorer.exe", arguments: [Target], }
      }
    MacOS => {
      // Preserve URL opening through PATH and the directory opener's full path.
      program: match kind {
        Url => "open"
        Directory => "/usr/bin/open"
      },
      arguments: [Target],
    }
    Linux => { program: "xdg-open", arguments: [Target], }
  }
}
