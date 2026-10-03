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
fn Model::pane_at(model : Model, idx : PaneSide) -> Pane {
  match idx {
    Left => model.panes.0.current
    Right => model.panes.1.current
  }
}

///|
fn set_pane(
  panes : (PaneStack, PaneStack),
  idx : PaneSide,
  pane : Pane,
) -> (PaneStack, PaneStack) {
  match idx {
    Left => ({ ..panes.0, current: pane, }, panes.1)
    Right => (panes.0, { ..panes.1, current: pane, })
  }
}
