///|
pub suberror ExtractionError {
  UnsafePath(String)
  ChecksumMismatch(String)
}

///|
pub extend ExtractionError with Show::{to_string, output}

///|
pub impl Show for ExtractionError with fn to_string(self) {
  match self {
    UnsafePath(name) => "Unsafe archive path: \{name}"
    ChecksumMismatch(name) => "ZIP checksum mismatch: \{name}"
  }
}

///|
/// Validate before Path normalization can hide absolute paths or dot segments.
/// Windows additionally aliases trailing dots/spaces and device filenames.
fn extraction_components(name : String) -> Array[String] raise ExtractionError {
  let relative = if name.has_suffix("/") {
    name.view(end_offset=name.length() - 1).to_owned()
  } else {
    name
  }
  let components = relative.split("/").map(part => part.to_owned()).to_array()
  for component in components {
    guard @shared.is_valid_archive_name(component) else {
      raise UnsafePath(name)
    }
    if @path.sep == '\\' {
      guard !component.has_suffix(".") && !component.has_suffix(" ") else {
        raise UnsafePath(name)
      }
      let stem = component.split(".").next().unwrap().to_owned().to_lower()
      guard ![
        "con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6",
        "com7", "com8", "com9", "lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7",
        "lpt8", "lpt9", "com¹", "com²", "com³", "lpt¹", "lpt²", "lpt³",
      ].contains(stem) else {
        raise UnsafePath(name)
      }
    }
  }
  components
}

///|
/// Own a fresh output tree, so failures can remove it without touching existing
/// files. The ZIP reader materializes entries in memory and checks structure;
/// CRC verification is the caller's responsibility.
pub async fn unzip_entries(source : Path, destination : Path) -> Unit {
  guard @async_fs.kind(source.to_string(), follow_symlink=false) is Regular else {
    raise ArchiveError::UnsupportedEntry(source.to_string())
  }
  @async_fs.mkdir(destination.to_string(), allow_exist=false)
  errdefer @fsops.cleanup_copy(destination)
  let data = @async_fs.read_file(source.to_string())
  let archive = @zip.read(data.binary())
  for entry in archive.entries() {
    let name = entry.name()
    let components = extraction_components(name)
    guard !components.any(part => part == ".DS_Store" || part == "__MACOSX") else {
      continue
    }
    guard @checksum.crc32(entry.data()) == entry.crc32() else {
      raise ChecksumMismatch(name)
    }
    let output = destination.join(Path(components.join("/")))
    if name.has_suffix("/") {
      @async_fs.mkdir(output.to_string(), recursive=true, allow_exist=true)
    } else {
      @async_fs.mkdir(
        output.dirname().to_string(),
        recursive=true,
        allow_exist=true,
      )
      let file = @async_fs.create(output.to_string(), allow_existing=false)
      defer file.close()
      let bytes = entry.data()
      for offset = 0; offset < bytes.length(); offset = offset + 64 * 1024 {
        file.write(bytes[offset:offset + 64 * 1024])
        @async.pause()
      }
    }
    @async.pause()
  }
}
