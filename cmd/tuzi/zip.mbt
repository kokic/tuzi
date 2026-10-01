///|
priv suberror ArchiveError {
  InvalidName(String)
  EmptySelection
  UnsupportedEntry(String)
  OutputIsInput(String)
}

///|
/// Bridge the synchronous ZIP sink to async writes. Drain after every writer
/// operation so file payloads never accumulate beyond one input chunk plus
/// codec buffers. ZIP central-directory metadata still scales with entry count.
priv struct ZipOutput {
  file : @async_fs.File
  mut pending : Array[Bytes]
}

///|
async fn ZipOutput::flush(self : ZipOutput) -> Unit {
  let pending = self.pending
  self.pending = []
  for bytes in pending {
    self.file.write(bytes)
  }
  // Even a buffered read or a chunk producing no output must yield to other tasks.
  @async.pause()
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
) -> Unit raise {
  validate_entry_name(output_name)
  guard !names.is_empty() else { raise EmptySelection }
  names.each(validate_archive_name)
  guard !names.contains(output_name) else { raise OutputIsInput(output_name) }
}

///|
async fn zip_entries(path : Path, names : Array[String], name : String) -> Unit {
  let output = path.join(Path("./\{name}")).to_string()
  let file = @async_fs.create(output, allow_existing=false)
  defer file.close()
  errdefer {
    file.close()
    @async_fs.remove(output)
  }
  let sink : ZipOutput = { file, pending: [], }
  let writer = @zip.Writer(bytes => sink.pending.push(bytes.to_owned()))
  for entry in names {
    add_archive_entry(writer, sink, path.join(Path("./\{entry}")), entry)
  }
  writer.finish()
  sink.flush()
}

///|
/// Explicit directory entries preserve empty folders. Never follow symlinks:
/// a link may lead outside the selection or back into its own directory tree.
async fn add_archive_entry(
  writer : @zip.Writer,
  sink : ZipOutput,
  path : Path,
  name : String,
) -> Unit {
  let basename = path.basename()
  guard basename != ".DS_Store" && basename != "__MACOSX" else { return }
  let kind = @async_fs.kind(path.to_string(), follow_symlink=false)
  match kind {
    Directory => {
      writer.add(name + "/", b"", compression=Store)
      sink.flush()
      let dir = @async_fs.opendir(path.to_string())
      defer dir.close()
      while dir.next(include_hidden=true, include_special=false) is Some(entry) {
        validate_archive_name(entry.name)
        add_archive_entry(
          writer,
          sink,
          path.join(Path("./\{entry.name}")),
          name + "/" + entry.name,
        )
      }
    }
    Regular => {
      let file = @async_fs.open(path.to_string(), mode=ReadOnly)
      defer file.close()
      writer.begin_entry(
        name,
        compression=archive_compression(basename),
        size=file.size().reinterpret_as_uint64(),
      )
      sink.flush()
      while file.read_some(max_len=64 * 1024) is Some(data) {
        writer.write(data)
        sink.flush()
      }
      writer.end_entry()
      sink.flush()
    }
    _ => raise ArchiveError::UnsupportedEntry(path.to_string())
  }
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
  guard stored_archive_extensions.binary_search(extension) is Err(_) else {
    return Store
  }
  return Deflate
}
