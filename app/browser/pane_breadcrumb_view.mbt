///|
fn breadcrumbs_view(
  path : Path,
  view_id : Int,
  idx : PaneSide,
  emit : Emit[Msg],
  openers : @tuzi.OpenRegistry?,
  other_path : Val[Path],
  drive_menu~ : Val[Html]?,
) -> Val[Html] {
  let segments = @vector.Vector::from_array(
    breadcrumb_segments(path).mapi((index, pair) => (index, pair.0, pair.1)),
  )
  Val::constant(segments)
  .assoc_by(
    (index, segment) => {
      segment.switch_by(
        segment => {
          let (_, part, target) = segment
          if index == 0 && drive_menu is Some(menu) {
            return menu
          }
          // The current directory remains clickable to reload the pane.
          let attrs = if target == path {
            @html.Attrs::build().aria_current("page")
          } else {
            @html.Attrs::build()
          }
          let button = @rui.button(
            variant=Ghost,
            size=Xs,
            title=part,
            style=[
              UI_FONT_STYLE,
              "min-width: 0",
              "flex-shrink: 1",
              "font-size: inherit",
              "line-height: inherit",
              "--rui-button-base-fg: var(--rui-muted-foreground)",
            ],
            attrs~,
            on_click=emit(PaneEvent(GotoPath(idx, target))),
            span(style=status_text_style(), part),
          )
          breadcrumb_context_menu(
            "pane-\{idx.index()}-view-\{view_id}-path-\{index}",
            target,
            idx,
            button,
            other_path,
            openers,
            emit,
          )
        },
        by=segment => segment.2.to_string(),
      )
    },
    by=segment => segment.0,
  )
  .view(segments => {
    let items : Array[Html] = []
    for segment in segments {
      if !items.is_empty() {
        items.push(@rui.breadcrumb_separator())
      }
      items.push(@rui.breadcrumb_item(style=["max-width: 100%"], segment))
    }
    @rui.breadcrumb(
      aria_label="Directory path",
      style=[
        UI_FONT_STYLE,
        "flex: 1",
        "min-width: 0",
        "--rui-ghost-hover-bg: transparent",
      ],
      @rui.breadcrumb_list(
        style=["font-size: inherit", "line-height: inherit"],
        items,
      ),
    )
  })
}

///|
priv enum BreadcrumbMenuMsg {
  Load
  Loaded(Result[Entry, RequestFailure])
}

///|
fn breadcrumb_context_menu(
  id : String,
  path : Path,
  idx : PaneSide,
  trigger : Html,
  other_path : Val[Path],
  openers : @tuzi.OpenRegistry?,
  emit : Emit[Msg],
) -> Val[Html] {
  let request = (send : Emit[BreadcrumbMenuMsg]) => {
    request_api(
      "/api/entry",
      body=ToJson::to_json(@tuzi.DirectoryRequest::{ path, }),
      result => send(Loaded(result)),
    )
  }
  let initial : Result[Entry, RequestFailure]? = None
  let (entry, send) = @rabbita.create_state_with_init(
    init=send => (initial, request(send)),
    update=(_entry : Result[Entry, RequestFailure]?, message, send) => {
      match message {
        Load => (None, request(send))
        Loaded(result) => (Some(result), @rabbita.none)
      }
    },
  )
  entry
  .map2(other_path, (entry, other_path) => (entry, path.dirname() == other_path))
  .switch_by(
    value => {
      let (entry, transfer_disabled) = value
      // Keep navigation available while metadata loads; the menu uses real entry data.
      guard entry is Some(entry) else { return Val::constant(trigger) }
      @rui.context_menu(id~, style=["min-width: 0"], scope => {
        fragment([
          @rui.context_menu_trigger(
            scope,
            tabindex=-1,
            style=["min-width: 0"],
            trigger,
          ),
          match entry {
            Ok(entry) => {
              let target : OpenTarget = { pane: idx, path, entry, }
              entry_menu_content(
                scope,
                target,
                openers,
                emit,
                emit.map(action => BreadcrumbAction(target, action)),
                transfer_disabled~,
              )
            }
            Err(error) =>
              @rui.context_menu_content(scope, style=[UI_FONT_STYLE], [
                @rui.context_menu_item(
                  scope,
                  disabled=true,
                  title=error.message(),
                  "Could not load directory actions",
                ),
                @rui.context_menu_item(scope, on_select=send(Load), "Retry"),
              ])
          },
        ])
      })
    },
    by=value => "\{value.0 is Some(_)}-\{value.1}",
  )
}

///|
fn breadcrumb_segments(path : Path) -> Array[(String, Path)] {
  for current = path, parts = [] {
    let parent = current.dirname()
    guard parent != current else {
      break [(current.to_string(), current), ..parts]
    }
    continue parent, [(current.basename(), current), ..parts]
  }
}
