///|
fn format_entry_meta(entry : Entry) -> String {
  let parts = [
    entry.mtime.map_or("", time => format_timestamp(time)),
    ..if !entry.is_dir {
      [entry.size.map_or("Unknown size", size => format_file_size(size))]
    },
  ]
  parts.filter(part => !part.is_empty()).join(" ")
}
