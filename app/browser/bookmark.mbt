///|
priv enum BookmarkMsg {
  AddCurrent
  Open
  Remove(Path)
  Jump(Path)
}

///|
fn Model::update_bookmarks(
  model : Model,
  msg : BookmarkMsg,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match msg {
    AddCurrent => {
      guard model.startup is Started else { return (model, @rabbita.none) }
      let path = model.pane_at(model.active).path
      guard !model.bookmarks.contains(path) else {
        return (
          model,
          emit(
            Toast(
              "Directory already bookmarked",
              Some(path.to_string()),
              @rui.ToastDefault,
            ),
          ),
        )
      }
      let bookmarks = [..model.bookmarks, path]
      ({ ..model, bookmarks, }, save_bookmarks(bookmarks, emit, added=path))
    }
    Open =>
      (
        { ..model, dialog: Bookmarks(model.active), dialog_error: "", },
        @rabbita.none,
      )
    Remove(path) => {
      guard model.dialog is Bookmarks(side) && model.bookmarks.contains(path) else {
        return (model, @rabbita.none)
      }
      (
        {
          ..model,
          dialog: BookmarkDeleteConfirm(side~, path~),
          dialog_error: "",
        },
        @rabbita.none,
      )
    }
    Jump(path) => {
      guard model.dialog is Bookmarks(side) && model.bookmarks.contains(path) else {
        return (model, @rabbita.none)
      }
      let (updated, command) = model.navigate_to_directory(side, path)
      (updated, @rabbita.batch([@dialog.close(DialogId), command]))
    }
  }
}

///|
fn Model::confirm_bookmark_delete(
  model : Model,
  side : PaneSide,
  path : Path,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let bookmarks = model.bookmarks.filter(bookmark => bookmark != path)
  (
    { ..model, bookmarks, dialog: Bookmarks(side), dialog_error: "", },
    save_bookmarks(bookmarks, emit),
  )
}
