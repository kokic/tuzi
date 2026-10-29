///|
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
    CreateLink(target~, destination~) => {
      @fsops.validate_link_target(target)
      @fsops.validate_link_path(destination)
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

///|
async fn execute_file_operation(operation : @shared.FileOperation) -> Unit {
  match operation {
    Delete(target~) => @fsops.remove_entry(target)
    Rename(source~, new_name~) => @fsops.rename_entry(source, new_name)
    EditLink(source~, destination~, target~) =>
      @fsops.edit_link(source, destination, target)
    CreateLink(target~, destination~) => @fsops.create_link(target, destination)
    CreateFile(parent~, name~) => @fsops.create_file_entry(parent, name)
    Mkdir(parent~, name~) => @fsops.mkdir_entry(parent, name)
    Zip(directory~, names~, output_name~, level~) =>
      @archive.zip_entries(directory, names, output_name, level~)
    Unzip(source~, destination~) => @archive.unzip_entries(source, destination)
    Copy(source~, destination~) => @fsops.copy_entry(source, destination)
    Move(source~, destination~) => @fsops.move_entry(source, destination)
  }
}
