///|
/// Explicit reloads affect only the displayed directories.
fn Model::invalidate_panes(model : Model, left~ : Bool, right~ : Bool) -> Model {
  let panes = set_pane(model.panes, Left, {
    ..model.panes.0.current,
    refresh_pending: model.panes.0.current.refresh_pending || left,
  })
  let panes = set_pane(panes, Right, {
    ..model.panes.1.current,
    refresh_pending: model.panes.1.current.refresh_pending || right,
  })
  { ..model, panes, }
}

///|
/// Apply a shared response to both panes before scheduling further work.
fn Model::receive_listing(
  model : Model,
  targets : Array[ListingTarget],
  path : Path,
  include_markers : Bool,
  result : Result[Array[Entry], RequestFailure],
) -> Model {
  targets.fold(init=model, (model, target) => {
    let { pane: idx, view_id, request_id, } = target
    let receive = (pane : Pane) => {
      guard pane.id == view_id &&
        pane.path == path &&
        pane.request_id == request_id else {
        return pane
      }
      if include_markers != (model.entry_appearance != Plain) {
        // A response for the previous entry appearance cannot satisfy this view.
        { ..pane, loading: Unloaded, refresh_pending: true, }
      } else {
        match result {
          Ok(entries) =>
            {
              ..pane.with_entries(
                entries,
                model.sort_order(idx),
                filter?=model.entry_filter(idx),
              ),
              loading: Ready,
            }
          Err(error) => { ..pane, loading: LoadFailed(error.message()), }
        }
      }
    }
    {
      ..model,
      panes: match idx {
        Left => (model.panes.0.map_views(receive), model.panes.1)
        Right => (model.panes.0, model.panes.1.map_views(receive))
      },
    }
  })
}

///|
/// Start at most one request per visible directory. An in-flight request is
/// allowed to finish; accumulated invalidations cause one subsequent request.
fn Model::load_pending_panes(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  guard model.startup is Started else { return (model, @rabbita.none) }
  let left = model.panes.0.current
  let right = model.panes.1.current
  let same_path = left.path == right.path
  guard !(same_path && (left.loading is Loading || right.loading is Loading)) else {
    return (model, @rabbita.none)
  }
  let reload_left = left.refresh_pending && !(left.loading is Loading)
  let reload_right = right.refresh_pending && !(right.loading is Loading)
  guard reload_left || reload_right else { return (model, @rabbita.none) }
  let left = if reload_left { left.begin_loading() } else { left }
  let right = if reload_right { right.begin_loading() } else { right }
  let command = if reload_left && reload_right && same_path {
    request_directory_listing(
      [
        { pane: Left, view_id: left.id, request_id: left.request_id, },
        { pane: Right, view_id: right.id, request_id: right.request_id, },
      ],
      left.path,
      model.entry_appearance != Plain,
      emit,
    )
  } else {
    @rabbita.batch(
      [
        ..if reload_left {
          [
            request_directory_listing(
              [{ pane: Left, view_id: left.id, request_id: left.request_id, }],
              left.path,
              model.entry_appearance != Plain,
              emit,
            ),
          ]
        },
        ..if reload_right {
          [
            request_directory_listing(
              [
                {
                  pane: Right,
                  view_id: right.id,
                  request_id: right.request_id,
                },
              ],
              right.path,
              model.entry_appearance != Plain,
              emit,
            ),
          ]
        },
      ],
    )
  }
  (
    {
      ..model,
      panes: set_pane(set_pane(model.panes, Left, left), Right, right),
    },
    command,
  )
}
