///|
async fn execute_file_operation(operation : @shared.FileOperation) -> Unit {
  match operation {
    Delete(target~) => @fsops.remove_entry(target)
    Rename(source~, new_name~) => @fsops.rename_entry(source, new_name)
    EditLink(source~, destination~, target~) =>
      @fsops.edit_link(source, destination, target)
    CreateFile(parent~, name~) => @fsops.create_file_entry(parent, name)
    Mkdir(parent~, name~) => @fsops.mkdir_entry(parent, name)
    Zip(directory~, names~, output_name~, level~) =>
      @archive.zip_entries(directory, names, output_name, level~)
    Unzip(source~, destination~) => @archive.unzip_entries(source, destination)
    Copy(source~, destination~) => @fsops.copy_entry(source, destination)
    Move(source~, destination~) => @fsops.move_entry(source, destination)
  }
}
