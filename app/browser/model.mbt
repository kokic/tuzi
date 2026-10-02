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
priv enum NewEntryKind {
  File
  Folder
}

///|
priv enum Dialog {
  None
  Help
  Activity
  TaskDetails(Int)
  Info(InfoContext)
  Markdown(MarkdownContext)
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
  NewEntryInput(directory~ : Path, input~ : String)
  GitRenameInput(context~ : GitContext, reference~ : String, input~ : String)
  Progress(ProgressBatch)
} derive(Eq)

///|
priv struct Model {
  startup : StartupState
  theme : Theme
  icons : IconMode
  openers : @tuzi.OpenRegistry?
  supports_drive_selection : Bool
  panes : (PaneStack, PaneStack)
  active : PaneSide
  sort : SortMode
  filters : (String, String)
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
  OpenWith(OpenTarget, String)
  EntryAction(PaneSide, Int, String, Msg)
  TransferSelection(TransferKind)
  CopyPaths
  MarkdownEvent(MarkdownMsg)
  GitEvent(GitMsg)
  TaskEvent(TaskMsg)
  DeleteOpen
  RenameOpen
  ZipOpen
  ZipLevelChanged(String)
  ActivityOpen
  NewEntryOpen
  NewEntrySubmit(NewEntryKind)
  FilterFocus(PaneSide, Bool)
  FilterChanged(PaneSide, String)
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
    supports_drive_selection: false,
    panes: (PaneStack::initialize(Path("")), PaneStack::initialize(Path(""))),
    active: Left,
    sort: Name,
    filters: ("", ""),
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
fn Model::filter_text(model : Model, idx : PaneSide) -> String {
  match idx {
    Left => model.filters.0
    Right => model.filters.1
  }
}

///|
fn Model::entry_filter(model : Model, idx : PaneSide) -> String? {
  let filter = model.filter_text(idx)
  guard !filter.is_empty() else { None }
  Some(filter)
}

///|
fn Model::with_filter(model : Model, idx : PaneSide, text : String) -> Model {
  let filter : String? = if text.is_empty() { None } else { Some(text) }
  {
    ..model,
    filters: match idx {
      Left => (text, model.filters.1)
      Right => (model.filters.0, text)
    },
    panes: match idx {
      Left =>
        (
          model.panes.0.map_views(pane => pane.with_filter(filter?)),
          model.panes.1,
        )
      Right =>
        (
          model.panes.0,
          model.panes.1.map_views(pane => pane.with_filter(filter?)),
        )
    },
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
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter(Left))
      }),
      model.panes.1.map_views(pane => {
        pane.with_entries(pane.entries, sort, filter?=model.entry_filter(Right))
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
