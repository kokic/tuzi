///|
priv enum GitMsg {
  GitRefresh(Int)
  GitLoaded(Int, Int, Result[@tuzi.GitInfo, RequestFailure])
  GitSelectBranch(Int, String)
  GitRun(Int, GitOperation)
  GitRenameOpen(Int)
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
  request_id : Int
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
