///|
priv enum PaneSide {
  Left
  Right
} derive(Eq)

///|
fn PaneSide::other(self : PaneSide) -> PaneSide {
  match self {
    Left => Right
    Right => Left
  }
}

///|
fn PaneSide::index(self : PaneSide) -> Int {
  match self {
    Left => 0
    Right => 1
  }
}

///|
priv enum StartupState {
  Starting
  Started
  StartupFailed(String)
} derive(Eq)

///|
priv enum Dialog {
  None
  Help
  Activity
  TaskDetails(Int)
  Info(InfoContext)
  OpenWith(OpenWithContext)
  GitInfo(GitContext)
  DeleteConfirm(directory~ : Path, names~ : Array[String])
  RenameInput(directory~ : Path, original~ : String, input~ : String)
  ZipInput(
    directory~ : Path,
    names~ : Array[String],
    input~ : String,
    level~ : Int
  )
  UnzipInput(source~ : Path, input~ : String)
  MkdirInput(directory~ : Path, input~ : String)
  GitRenameInput(context~ : GitContext, reference~ : String, input~ : String)
  Progress(ProgressBatch)
} derive(Eq)

///|
priv struct Model {
  startup : StartupState
  theme : Theme
  icons : IconMode
  openers : @tuzi.OpenRegistry?
  panes : (PaneStack, PaneStack)
  active : PaneSide
  sort : SortMode
  filter : String
  editing : Bool
  dialog : Dialog
  // Late submission replies only update the dialog that initiated them.
  dialog_revision : Int
  // Validation message shown inside the open dialog; cleared on input/cancel.
  dialog_error : String
  dragging : DragSelection?
  jobs : TaskState
  next_info_id : Int
} derive(Eq)

///|
priv enum Msg {
  BaseLoaded(@tuzi.ServerConfig)
  BaseFailed(String)
  BaseRetry
  PaneEvent(PaneMsg)
  Key(@dom.KeyboardEvent)
  SortCycle
  ThemeToggle
  HelpOpen
  InfoOpen
  OpenWithOpen
  OpenWithChanged(String)
  GitEvent(GitMsg)
  TaskEvent(TaskMsg)
  DeleteOpen
  RenameOpen
  ZipOpen
  ZipLevelChanged(String)
  ActivityOpen
  MkdirOpen
  FilterFocus(Bool)
  FilterChanged(String)
  DialogInput(String)
  DialogCancel
  DialogSubmit
  DragStart(PaneSide, String)
  Drop(PaneSide)
  DragEnd
  Toast(String, String?, @rui.ToastVariant)
}

///|
fn Model::initialize() -> Model {
  {
    startup: Starting,
    theme: Theme::default_theme(),
    icons: IconMode::default_mode(),
    openers: None,
    panes: (PaneStack::initialize(Path("")), PaneStack::initialize(Path(""))),
    active: Left,
    sort: Name,
    filter: "",
    editing: false,
    dialog: None,
    dialog_revision: 0,
    dialog_error: "",
    dragging: None,
    jobs: TaskState::initialize(),
    next_info_id: 0,
  }
}

///|
fn Model::entry_filter(model : Model) -> String? {
  guard !model.filter.is_empty() else { None }
  Some(model.filter)
}

///|
fn Model::with_filter(model : Model, text : String) -> Model {
  let filter : String? = if text.is_empty() { None } else { Some(text) }
  {
    ..model,
    filter: text,
    panes: (
      model.panes.0.map_views(pane => pane.with_filter(filter?)),
      model.panes.1.map_views(pane => pane.with_filter(filter?)),
    ),
  }
}

///|
fn Model::cycle_sort_order(model : Model) -> Model {
  let sort = model.sort.next()
  {
    ..model,
    sort,
    panes: (
      model.panes.0.map_views(pane => {
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter())
      }),
      model.panes.1.map_views(pane => {
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter())
      }),
    ),
  }
}

///|
priv enum TransferKind {
  Copy
  Move
}

///|
priv struct DragSelection {
  source_pane : PaneSide
  directory : Path
  names : Array[String]
} derive(Eq)
