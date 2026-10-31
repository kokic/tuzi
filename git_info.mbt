///|
pub(all) struct GitBranch {
  reference : String
  name : String
} derive(Eq, FromJson, ToJson)

///|
pub fn GitBranch::is_remote(self : GitBranch) -> Bool {
  self.reference.has_prefix("refs/remotes/")
}

///|
pub fn GitBranch::local_name(self : GitBranch) -> String? {
  self.reference.strip_prefix("refs/heads/").map(name => name.to_owned())
}

///|
pub extend GitBranch with Eq::{equal, not_equal}

///|
pub extend GitBranch with FromJson::{from_json}

///|
pub extend GitBranch with ToJson::{to_json}

///|
pub(all) struct GitWorktree {
  path : Path
  head : String
  branch : String?
  main : Bool
  current : Bool
  bare : Bool
  detached : Bool
  locked : Bool
  prunable : Bool
} derive(Eq, FromJson, ToJson)

///|
pub fn GitWorktree::can_remove(self : GitWorktree) -> Bool {
  !self.main && !self.current && !self.bare && !self.locked
}

///|
pub fn GitWorktree::label(self : GitWorktree) -> String {
  let name = self.path.basename()
  if name.is_empty() {
    self.path.to_string()
  } else {
    name
  }
}

///|
pub fn GitWorktree::branch_name(self : GitWorktree) -> String? {
  guard self.branch is Some(branch) else { return None }
  branch.strip_prefix("refs/heads/").map(name => name.to_owned())
}

///|
pub fn GitWorktree::short_head(self : GitWorktree) -> String {
  if self.head.length() > 8 {
    self.head[:8].to_owned()
  } else {
    self.head
  }
}

///|
pub extend GitWorktree with Eq::{equal, not_equal}

///|
pub extend GitWorktree with FromJson::{from_json}

///|
pub extend GitWorktree with ToJson::{to_json}

///|
pub(all) struct GitInfo {
  available : Bool
  current : String
  branches : Array[GitBranch]
  worktrees : Array[GitWorktree]
} derive(Eq, FromJson, ToJson)

///|
pub fn GitInfo::worktree_for_branch(
  self : GitInfo,
  reference : String,
) -> GitWorktree? {
  self.worktrees
  .iter()
  .find_first(worktree => worktree.branch == Some(reference))
}

///|
pub extend GitInfo with Eq::{equal, not_equal}

///|
pub extend GitInfo with FromJson::{from_json}

///|
pub extend GitInfo with ToJson::{to_json}
