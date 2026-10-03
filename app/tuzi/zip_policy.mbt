///|
priv suberror ArchiveError {
  InvalidName(String)
  EmptySelection
  UnsupportedEntry(String)
  OutputIsInput(String)
  InvalidCompressionLevel(Int)
}

///|
/// Keep both the output and selected entries inside the requested directory.
fn validate_archive_name(name : String) -> Unit raise ArchiveError {
  guard @shared.is_valid_archive_name(name) else { raise InvalidName(name) }
}

///|
/// The output is a host filename; only stored entries use ZIP path rules.
fn validate_zip_selection(
  names : Array[String],
  output_name : String,
  level~ : Int,
) -> Unit raise {
  guard level >= 0 && level <= 9 else { raise InvalidCompressionLevel(level) }
  validate_entry_name(output_name)
  guard !names.is_empty() else { raise EmptySelection }
  names.each(validate_archive_name)
  guard !names.contains(output_name) else { raise OutputIsInput(output_name) }
}

///|
/// Sorted lexicographically for binary search; keep new extensions in order.
let stored_archive_extensions : ReadOnlyArray[String] = [
  "7z", "aac", "apk", "apng", "avif", "br", "bz2", "docx", "ear", "epub", "flac",
  "gif", "gz", "heic", "heif", "ipa", "jar", "jfif", "jp2", "jpe", "jpeg", "jpg",
  "lz", "lz4", "lzma", "m4a", "m4v", "mkv", "mov", "mp3", "mp4", "odp", "ods", "odt",
  "ogg", "opus", "png", "pptx", "rar", "svgz", "tbz", "tbz2", "tgz", "txz", "tzst",
  "war", "webm", "webp", "woff", "woff2", "xlsx", "xz", "zip", "zst",
]

///|
/// A conservative extension policy: skip recompression for common compressed
/// formats, but keep compressing text and uncompressed containers such as TAR,
/// BMP and WAV. Unknown extensions still use Deflate.
fn archive_compression(name : String) -> @zip.Compression {
  guard name.rev_find(".") is Some(dot) else { return Deflate }
  let extension = name.view(start_offset=dot + 1).to_owned().to_lower()
  guard stored_archive_extensions.binary_search_by(ext => {
      ext.lexical_compare(extension)
    })
    is Err(_) else {
    return Store
  }
  return Deflate
}
