///|
let default_port : UInt16 = 4000

///|
async fn main {
  let cmd = build_command().parse()
  let port = server_port(@env.get_env_vars(), cmd)
  let openers = OpenService::new()
  let config = parse_server_config(cmd, openers.registry)
  let headless = cmd.flags.get("headless").unwrap_or(false)
  let log = !cmd.flags.get("silent").unwrap_or(false)
  let resources = static_resources()
  let tasks = TaskService::new()
  @async.with_task_group(group => {
    let app = @moonback.App(
      ctx => {
        ctx.add_middleware(resources)
        routes(config, log, tasks, group, openers)(ctx)
      },
      config=@moonback.Config(stop_timeout=0),
    )
    defer app.close()
    let listener = @moonback.listen(reuse_addr=true, port~)
    if !headless {
      launch_browser(port)
    }
    app.serve(listener)
  })
}

///|
fn static_resources() -> @moonback.Middleware {
  let assets = warren_assets()
  if assets.is_empty() {
    let root = {
      guard @env.get_env_var("WARREN_DIST") is Some(root) else {
        @path.Path(@env.args()[0]).resolve().dirname().to_string()
      }
      root
    }
    @static.new(root~, rewrite_trailing_slash_index=true)
  } else {
    @static.from_assets(assets, rewrite_trailing_slash_index=true)
  }
}

///|
fn build_command() -> @argparse.Command {
  Command(
    "tuzi",
    about="A minimal file browser",
    flags=[
      FlagArg("headless", about="run without opening the browser"),
      FlagArg("silent", about="disable logging of file operations"),
    ],
    options=[
      OptionArg(
        "entry-appearance",
        about="entry appearance: plain or decorated (file type colors), default \{@shared.EntryAppearance::default().to_string()}",
      ),
      OptionArg("port", short='p', about="server port, default \{default_port}"),
      OptionArg(
        "theme",
        short='t',
        about="color theme: light or dark, default \{@shared.Theme::default().to_string()}",
      ),
    ],
    positionals=[
      PositionArg("path", about="directory to open (default: history or cwd)"),
    ],
  )
}

///|
/// The server port: `WARREN_PORT` (set by `warren dev`) wins over the
/// `-p` flag; otherwise use `default_port`.
fn server_port(
  env : Map[String, String],
  cmd : @argparse.Matches,
) -> UInt16 raise {
  let port = match () {
    _ if env.get("WARREN_PORT") is Some(port) => port
    _ if cmd.values.get("port") is Some([port]) => port
    _ => return default_port
  }
  @string.parse_uint(port).to_uint16()
}

///|
fn parse_server_config(
  cmd : @argparse.Matches,
  openers : @shared.OpenRegistry,
) -> @shared.ServerConfig {
  let (path, startup) : (@path.Path, @shared.StartupMode) = match cmd.values {
    { "path": [path], .. } => (Path(path), OpenDirectory)
    _ => (Path("."), RestoreHistory)
  }
  let base = Path::from_native(path.resolve().to_string())
  let theme = {
    guard cmd.values.get("theme") is Some([theme]) else {
      @shared.Theme::default()
    }
    @shared.Theme::parse(theme)
  }
  let entry_appearance = {
    guard cmd.values.get("entry-appearance") is Some([appearance]) else {
      @shared.EntryAppearance::default()
    }
    @shared.EntryAppearance::parse(appearance)
  }
  {
    base,
    startup,
    theme,
    entry_appearance,
    openers,
    supports_drive_selection: SupportsDriveSelection,
  }
}

///|
async fn launch_browser(port : UInt16) -> Unit {
  let url = "http://127.0.0.1:\{port}/"
  @stdio.stdout.write("tuzi: \{url}\n")
  system_open_command(Url).launch(url)
}
