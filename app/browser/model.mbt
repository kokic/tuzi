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
  bookmarks : Array[Path]
  filters : (String, String)
  editing : Bool
  dialog : Dialog
  // Late submission replies only update the dialog that initiated them.
  dialog_revision : Int
  // Validation message shown inside the open dialog; cleared on input/cancel.
  dialog_error : String
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
  BookmarkEvent(BookmarkMsg)
  Key(@dom.KeyboardEvent)
  SortCycle(PaneSide)
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
    bookmarks: load_bookmarks() catch {
      _ => []
    },
    filters: ("", ""),
    editing: false,
    dialog: None,
    dialog_revision: 0,
    dialog_error: "",
    jobs: TaskState::initialize(),
    next_info_id: 0,
  }
}

///|
fn Model::toggle_theme(model : Model) -> (Model, Cmd) {
  let theme : Theme = match model.theme {
    Light => Dark
    Dark => Light
  }
  ({ ..model, theme, }, @rabbita.none)
}
