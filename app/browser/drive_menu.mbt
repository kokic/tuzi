///|
priv struct DriveMenuState {
  open : Bool
  request_id : Int
  listing : Result[Array[Path], RequestFailure]?
} derive(Eq)

///|
priv enum DriveMenuMsg {
  SetOpen(Bool)
  Loaded(Int, Result[Array[Path], RequestFailure])
}

///|
fn drive_menu_view(
  id : String,
  root : Path,
  directory : Path,
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  let (state, send) = @rabbita.create_state(
    DriveMenuState::{ open: false, request_id: 0, listing: None, },
    update=(state, message, send) => {
      match message {
        SetOpen(false) => ({ ..state, open: false, }, @rabbita.none)
        SetOpen(true) => {
          let request_id = state.request_id + 1
          (
            { open: true, request_id, listing: None, },
            request_api("/api/drives", result => {
              send(Loaded(request_id, result))
            }),
          )
        }
        Loaded(request_id, result) => {
          guard request_id == state.request_id else {
            return (state, @rabbita.none)
          }
          ({ ..state, listing: Some(result), }, @rabbita.none)
        }
      }
    },
  )
  // Rebuild the menu contents when a request starts/finishes, retaining its
  // current open state. A reply after dismissal must not reopen the menu.
  state.switch_by(
    state => {
      @rui.dropdown_menu(
        id~,
        default_open=state.open,
        on_open_change=send.map(open => SetOpen(open)),
        scope => {
          let items = if state.listing is Some(listing) {
            match listing {
              Ok(drives) => {
                let current = current_storage_location(directory, drives)
                if drives.is_empty() {
                  [
                    @rui.dropdown_menu_item(
                      scope,
                      disabled=true,
                      "No storage locations",
                    ),
                  ]
                } else {
                  drives.map(drive => {
                    @rui.dropdown_menu_item(
                      scope,
                      on_select=emit(PaneEvent(GotoPath(idx, drive))),
                      [
                        span(drive.to_string()),
                        ..if Some(drive) == current {
                          [@rui.dropdown_menu_shortcut("Current")]
                        },
                      ],
                    )
                  })
                }
              }
              Err(error) =>
                [
                  @rui.dropdown_menu_item(
                    scope,
                    disabled=true,
                    title=error.message(),
                    "Could not load storage locations",
                  ),
                  @rui.dropdown_menu_item(
                    scope,
                    close_on_select=false,
                    on_select=send(SetOpen(true)),
                    "Retry",
                  ),
                ]
            }
          } else {
            [
              @rui.dropdown_menu_item(
                scope,
                disabled=true,
                "Loading storage locations…",
              ),
            ]
          }
          fragment([
            @rui.dropdown_menu_trigger(
              scope,
              variant=Ghost,
              size=Xs,
              aria_label="Switch storage location",
              title="Switch storage location",
              style=[
                UI_FONT_STYLE,
                "font-size: inherit",
                "line-height: inherit",
                "--rui-button-base-fg: var(--rui-muted-foreground)",
              ],
              attrs=@html.Attrs::build()
                .on_contextmenu(event => {
                  event.prevent_default()
                  open_drive_menu(id)
                })
                .on_keydown(event => {
                  if event.key() == "ContextMenu" ||
                    (event.shift_key() && event.key() == "F10") {
                    event.prevent_default()
                    open_drive_menu(id)
                  } else {
                    @rabbita.none
                  }
                }),
              "\{root} ▾",
            ),
            @rui.dropdown_menu_content(
              scope,
              aria_label="Storage locations",
              style=[UI_FONT_STYLE],
              items,
            ),
          ])
        },
      )
    },
    by=state => "\{state.request_id}-\{state.listing is Some(_)}",
  )
}

///|
/// The deepest mount containing this directory is the current location.
fn current_storage_location(directory : Path, locations : Array[Path]) -> Path? {
  for current = directory {
    if locations.contains(current) {
      break Some(current)
    }
    let parent = current.dirname()
    guard parent != current else { break None }
    continue parent
  }
}

///|
/// Right-click uses the same menu and keyboard/focus behavior as left-click.
fn open_drive_menu(id : String) -> Cmd {
  @rabbita.effect(() => {
    guard @dom.document().get_element_by_id(id + "-trigger").to_option()
      is Some(element) &&
      element.to_html_element() is Some(trigger) else {
      return
    }
    trigger.click()
  })
}
