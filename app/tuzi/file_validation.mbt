///|
/// Check only request data; filesystem state is checked when the task executes.
fn validate_file_operation_input(
  operation : @shared.FileOperation,
) -> Unit raise {
  match operation {
    Delete(target~) => @fsops.validate_entry_name(target.basename())
    Rename(source~, new_name~) => {
      @fsops.validate_entry_name(source.basename())
      @fsops.validate_entry_name(new_name)
    }
    EditLink(source~, destination~, target~) => {
      @fsops.validate_link_path(source)
      @fsops.validate_link_path(destination)
      @fsops.validate_link_target(target)
    }
    CreateFile(name~, ..) | Mkdir(name~, ..) => @fsops.validate_entry_name(name)
    Zip(names~, output_name~, level~, ..) =>
      @archive.validate_zip_selection(names, output_name, level~)
    Unzip(source~, destination~) => {
      @fsops.validate_entry_name(source.basename())
      @fsops.validate_entry_name(destination.basename())
    }
    Copy(source~, destination~) | Move(source~, destination~) => {
      @fsops.validate_entry_name(source.basename())
      @fsops.validate_entry_name(destination.basename())
    }
  }
}
