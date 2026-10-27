///|
pub(all) struct JsonlRecord {
  line : Int32
  value : Json
} derive(Eq)

///|
pub(all) struct JsonlDocument {
  records : Array[JsonlRecord]
  diagnostics : Array[Diagnostic]
} derive(Eq)

///|
pub fn parse_jsonl(source : String) -> JsonlDocument {
  let records : Array[JsonlRecord] = []
  let diagnostics : Array[Diagnostic] = []
  for index, line in source.split("\n").iter2() {
    let line = if index == 0 {
      line.strip_prefix("\u{FEFF}").unwrap_or(line)
    } else {
      line
    }
    let line = line.trim()
    if line.is_empty() {
      continue
    }
    try {
      let value = @json.parse(line, preserve_number_repr=true)
      records.push({ line: index + 1, value, })
    } catch {
      error =>
        diagnostics.push({
          line: index + 1,
          message: error.to_string(),
          source: line.to_owned(),
        })
    }
  }
  { records, diagnostics, }
}

///|
pub extend JsonlRecord with Eq::{equal, not_equal}

///|
pub extend JsonlDocument with Eq::{equal, not_equal}
