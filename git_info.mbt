///|
/// A local or remote-tracking branch; full refs are used as stable API identifiers.
pub(all) struct GitBranch {
  reference : String
  name : String
} derive(Eq, FromJson, ToJson)

///|
pub fn GitBranch::is_remote(self : GitBranch) -> Bool {
  self.reference.has_prefix("refs/remotes/")
}

///|
/// The branch name for a local reference, excluding its refs/heads/ prefix.
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
/// An empty current branch denotes a detached HEAD.
pub(all) struct GitInfo {
  available : Bool
  current : String
  branches : Array[GitBranch]
} derive(Eq, FromJson, ToJson)

///|
pub extend GitInfo with Eq::{equal, not_equal}

///|
pub extend GitInfo with FromJson::{from_json}

///|
pub extend GitInfo with ToJson::{to_json}
