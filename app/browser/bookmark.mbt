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
      guard model.dialog is Bookmarks(_) && model.bookmarks.contains(path) else {
        return (model, @rabbita.none)
      }
      let bookmarks = model.bookmarks.filter(bookmark => bookmark != path)
      ({ ..model, bookmarks, }, save_bookmarks(bookmarks, emit))
    }
    Jump(path) => {
      guard model.dialog is Bookmarks(side) && model.bookmarks.contains(path) else {
        return (model, @rabbita.none)
      }
      let (updated, command) = model.navigate_to_directory(side, path)
      // The native close event clears the dialog, as with its Close button.
      (updated, @rabbita.batch([@dialog.close(DialogId), command]))
    }
  }
}
