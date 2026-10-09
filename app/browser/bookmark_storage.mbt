///|
/// Decode strings before constructing Paths so empty values are not saved as `.`.
fn decode_bookmarks(value : String) -> Array[Path] raise {
  let saved : Array[String] = @json.from_json(@json.parse(value))
  let bookmarks : Array[Path] = []
  for value in saved {
    if !value.is_empty() {
      let path = Path(value)
      if !bookmarks.contains(path) {
        bookmarks.push(path)
      }
    }
  }
  bookmarks
}

///|
fn load_bookmarks() -> Array[Path] raise {
  let value : @js.Value = @js.Error_::wrap(() => {
    let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
    storage.apply_with_string("getItem", [BookmarkStorageKey])
  })
  guard value.is_string() else { return [] }
  decode_bookmarks(value.to_string())
}

///|
fn save_bookmarks(
  bookmarks : Array[Path],
  emit : Emit[Msg],
  added? : Path,
) -> Cmd {
  let value = ToJson::to_json(bookmarks).stringify()
  @cmd.attempt(
    result => {
      match result {
        Ok(_) =>
          added.map_or(@rabbita.none, path => {
            emit(
              Toast(
                "Directory bookmarked",
                Some(path.to_string()),
                @rui.ToastSuccess,
              ),
            )
          })
        Err(_) =>
          emit(
            Toast(
              "Could not save bookmarks",
              Some("Changes are available in this session only."),
              @rui.ToastDestructive,
            ),
          )
      }
    },
    () => {
      @js.Error_::wrap(
        () => {
          let storage : @js.Value = @js.globalThis.get_with_string(
            "localStorage",
          )
          storage.apply_with_string("setItem", [BookmarkStorageKey, value])
        },
        map_ok=_ => (),
      )
    },
  )
}
