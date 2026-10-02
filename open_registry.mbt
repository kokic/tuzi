///|
/// Browser actions share the same association table as server-side programs.
pub(all) enum OpenAction {
  Browse
  Preview
  ExtractZip
  External
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct Opener {
  label : String
  action : OpenAction
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct OpenAssociation {
  /// Menu order is independent of the default action.
  openers : Array[String]
  default_opener : String
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct OpenRegistry {
  openers : Map[String, Opener]
  folder : OpenAssociation
  /// Lowercase complete filenames, including dotfiles.
  filenames : Map[String, OpenAssociation]
  /// Lowercase extensions without a leading dot; "" means no extension.
  extensions : Map[String, OpenAssociation]
  other_file : OpenAssociation
} derive(Eq, ToJson, FromJson)

///|
pub fn OpenRegistry::for_entry(
  self : OpenRegistry,
  name : String,
  is_dir~ : Bool,
) -> OpenAssociation {
  guard !is_dir else { return self.folder }
  let name = name.to_lower()
  if self.filenames.get(name) is Some(association) {
    return association
  }
  let extension = @posix.Path(name)
    .extname()
    .to_owned()
    .strip_prefix(".")
    .map_or("", suffix => suffix.to_owned())
  self.extensions.get(extension).unwrap_or(self.other_file)
}

///|
pub(all) struct OpenRequest {
  path : Path
  opener : String
} derive(ToJson, FromJson)

///|
pub extend OpenAction with Eq::{equal, not_equal}

///|
pub extend OpenAction with ToJson::{to_json}

///|
pub extend OpenAction with FromJson::{from_json}

///|
pub extend Opener with Eq::{equal, not_equal}

///|
pub extend Opener with ToJson::{to_json}

///|
pub extend Opener with FromJson::{from_json}

///|
pub extend OpenAssociation with Eq::{equal, not_equal}

///|
pub extend OpenAssociation with ToJson::{to_json}

///|
pub extend OpenAssociation with FromJson::{from_json}

///|
pub extend OpenRegistry with Eq::{equal, not_equal}

///|
pub extend OpenRegistry with ToJson::{to_json}

///|
pub extend OpenRegistry with FromJson::{from_json}

///|
pub extend OpenRequest with ToJson::{to_json}

///|
pub extend OpenRequest with FromJson::{from_json}
