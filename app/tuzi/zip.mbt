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
async fn zip_entries(
  path : Path,
  names : Array[String],
  name : String,
  level~ : Int,
) -> Unit {
  let output = path.join(Path("./\{name}")).to_string()
  let file = @async_fs.create(output, allow_existing=false)
  defer file.close()
  errdefer {
    file.close()
    @async_fs.remove(output)
  }
  let sink : ZipOutput = { file, pending: [], }
  let writer = @zip.Writer(bytes => sink.pending.push(bytes.to_owned()), level~)
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
