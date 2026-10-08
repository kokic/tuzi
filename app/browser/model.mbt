///|
priv enum StartupState {
  Starting
  Started
  StartupFailed(String)
} derive(Eq)

///|
priv struct Model {
  startup : StartupState
  theme : Theme
  entry_appearance : EntryAppearance
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
  SyncPanePath
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
  LinkTargetLoaded(Int, Result[Path, RequestFailure])
  LinkPathInput(String)
  LinkTargetInput(String)
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
    theme: Theme::default(),
    entry_appearance: EntryAppearance::default(),
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
