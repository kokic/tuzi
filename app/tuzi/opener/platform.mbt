///|
pub async fn open_url(url : String) -> Unit {
  system_open_command(Url).launch(url)
}

///|
priv enum SystemOpenKind {
  Url
  Directory
}

///|
#cfg(platform="windows")
fn system_open_command(kind : SystemOpenKind) -> OpenCommand {
  match kind {
    Url =>
      {
        program: "cmd",
        arguments: [Literal("/c"), Literal("start"), Literal(""), Target],
      }
    Directory => { program: "explorer.exe", arguments: [Target], }
  }
}

///|
#cfg(not(platform="windows"))
fn system_open_command(kind : SystemOpenKind) -> OpenCommand {
  match @async.platform {
    MacOS =>
      {
        program: match kind {
          Url => "open"
          Directory => "/usr/bin/open"
        },
        arguments: [Target],
      }
    Linux => { program: "xdg-open", arguments: [Target], }
    Windows => panic()
  }
}
