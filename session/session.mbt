///|
pub fn detect_agent(header : Json) -> Agent? {
  if string_field(header, "type") == Some("session") &&
    string_field(header, "id") is Some(_) &&
    string_field(header, "cwd") is Some(_) &&
    field(header, "version") is Some(Number(_)) {
    Some(Pi)
  } else {
    None
  }
}

///|
pub fn parse(source : String, agent? : Agent) -> Result[Document, String] {
  let jsonl = parse_jsonl(source)
  guard jsonl.records.get(0) is Some(header) else {
    return Err(
      if jsonl.diagnostics.get(0) is Some(issue) {
        "Line \{issue.line}: \{issue.message}"
      } else {
        "This file contains no session records."
      },
    )
  }
  guard !jsonl.diagnostics.any(issue => issue.line < header.line) else {
    let issue = jsonl.diagnostics[0]
    return Err(
      "Unable to read the session header at line \{issue.line}: \{issue.message}",
    )
  }
  let detected = detect_agent(header.value)
  guard detected is Some(detected) else {
    return Err(
      "Unsupported session format. Currently supported: pi JSONL v3. Use Preview text to inspect this file.",
    )
  }
  if agent is Some(expected) && expected != detected {
    return Err("The session header does not match the selected agent.")
  }
  match detected {
    Pi => parse_pi(jsonl)
  }
}

///|
fn field(value : Json, key : String) -> Json? {
  match value {
    Object(fields) => fields.get(key)
    _ => None
  }
}

///|
fn string_field(value : Json, key : String) -> String? {
  match field(value, key) {
    Some(String(text)) => Some(text)
    _ => None
  }
}

///|
fn bool_field(value : Json, key : String) -> Bool {
  field(value, key) is Some(True)
}
