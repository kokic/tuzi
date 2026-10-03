///|
using @path {type Path}

///|
/// Existing entries are identified by their full paths. New names identify one
/// child of the given parent; rename stays in the source directory, and ZIP
/// selections and output stay in one directory.
pub(all) enum FileOperation {
  Delete(target~ : Path)
  Rename(source~ : Path, new_name~ : String)
  EditLink(source~ : Path, destination~ : Path, target~ : Path)
  Zip(
    directory~ : Path,
    names~ : Array[String],
    output_name~ : String,
    level~ : Int
  )
  Unzip(source~ : Path, destination~ : Path)
  CreateFile(parent~ : Path, name~ : String)
  Mkdir(parent~ : Path, name~ : String)
  Copy(source~ : Path, destination~ : Path)
  Move(source~ : Path, destination~ : Path)
} derive(Eq, ToJson, FromJson)

///|
pub extend FileOperation with ToJson::{to_json}

///|
pub extend FileOperation with FromJson::{from_json}

///|
pub extend FileOperation with Eq::{equal, not_equal}

///|
pub fn FileOperation::description(operation : FileOperation) -> String {
  match operation {
    Delete(target~) => "delete \{target}"
    Rename(source~, new_name~) =>
      "rename \{source} -> \{source.dirname().join(Path("./\{new_name}"))}"
    EditLink(source~, destination~, target~) =>
      "edit link \{source} -> \{destination} (target: \{target})"
    Zip(directory~, output_name~, ..) =>
      "compress \{directory.join(Path("./\{output_name}"))}"
    Unzip(source~, destination~) => "extract \{source} -> \{destination}"
    CreateFile(parent~, name~) =>
      "create file \{parent.join(Path("./\{name}"))}"
    Mkdir(parent~, name~) => "create \{parent.join(Path("./\{name}"))}"
    Copy(source~, destination~) => "copy \{source} -> \{destination}"
    Move(source~, destination~) => "move \{source} -> \{destination}"
  }
}
