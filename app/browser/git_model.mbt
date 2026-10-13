///|
priv enum GitMsg {
  GitRefresh(Int32)
  GitLoaded(Int32, Int32, Result[@tuzi.GitInfo, RequestFailure])
  GitSelectBranch(Int32, String)
  GitRun(Int32, GitOperation)
  GitRenameOpen(Int32)
}

///|
priv struct GitContext {
  entry : InfoContext
  panel : GitPanel
} derive(Eq)

///|
priv struct GitPanel {
  info : @tuzi.GitInfo?
  loading : Bool
  request_id : Int32
  selected : String
  error : String
} derive(Eq)

///|
fn GitPanel::initialize() -> GitPanel {
  { info: None, loading: true, request_id: 0, selected: "", error: "", }
}

///|
fn GitPanel::receive(
  self : GitPanel,
  result : Result[@tuzi.GitInfo, RequestFailure],
) -> GitPanel {
  match result {
    Ok(info) =>
      {
        ..self,
        info: Some(info),
        loading: false,
        error: "",
        selected: if info.branches.any(branch => {
            branch.reference == self.selected
          }) {
          self.selected
        } else {
          ""
        },
      }
    Err(error) => { ..self, loading: false, error: error.message(), }
  }
}
