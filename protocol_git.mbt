///|
#derive(Eq, ToJson, FromJson)
pub(all) enum GitOperation {
  Pull
  Push
  Switch(String)
  DeleteBranch(String)
  RenameBranch(String, String)
  RemoveWorktree(Path)
  Prune
  PruneWorktrees
}

///|
pub fn GitOperation::name(self : GitOperation) -> String {
  match self {
    Pull => "pull"
    Push => "push"
    Switch(_) => "switch"
    DeleteBranch(_) => "delete-branch"
    RenameBranch(_, _) => "rename-branch"
    RemoveWorktree(_) => "remove-worktree"
    Prune => "prune"
    PruneWorktrees => "prune-worktrees"
  }
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct GitRequest {
  path : Path
  operation : GitOperation
}

///|
pub extend GitOperation with ToJson::{to_json}

///|
pub extend GitOperation with FromJson::{from_json}

///|
pub extend GitOperation with Eq::{equal, not_equal}

///|
pub extend GitRequest with ToJson::{to_json}

///|
pub extend GitRequest with FromJson::{from_json}

///|
pub extend GitRequest with Eq::{equal, not_equal}
