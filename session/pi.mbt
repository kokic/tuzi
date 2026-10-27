///|
fn parse_pi(jsonl : JsonlDocument) -> Result[Document, String] {
  let header = jsonl.records[0].value
  guard field(header, "version") is Some(Number(3.0, ..)) else {
    let version = field(header, "version").map_or("missing", value => {
      value.stringify()
    })
    return Err(
      "Unsupported pi session version: \{version}. Currently supported: v3.",
    )
  }
  let entries : Array[Entry] = []
  let diagnostics = jsonl.diagnostics.copy()
  let ids : Map[String, Bool] = Map([])
  let mut previous : String? = None
  for record in jsonl.records.iter().drop(1) {
    let value = record.value
    let id = string_field(value, "id")
    let parent_id = string_field(value, "parentId")
    let kind = string_field(value, "type").unwrap_or("Unknown record")
    let mut event = pi_event(value, kind)
    let problem = if id is None || id == Some("") {
      Some("The record has no valid entry ID.")
    } else if !(field(value, "parentId") is Some(Null | String(_))) {
      Some("The record has no valid parentId (expected a string or null).")
    } else if string_field(value, "timestamp") is None {
      Some("The record has no valid timestamp.")
    } else {
      None
    }
    if problem is Some(message) {
      diagnostics.push({
        line: record.line,
        message,
        source: value.stringify(),
      })
      event = Unknown(kind)
    }
    if id is Some(id) {
      if ids.contains(id) {
        diagnostics.push({
          line: record.line,
          message: "Duplicate entry ID: \{id}",
          source: value.stringify(),
        })
      }
      if parent_id is Some(parent) && !ids.contains(parent) {
        diagnostics.push({
          line: record.line,
          message: "Parent entry not found before this record: \{parent}",
          source: value.stringify(),
        })
      }
      ids[id] = true
    }
    entries.push({
      line: record.line,
      id: id.unwrap_or("line-\{record.line}"),
      parent_id,
      timestamp: string_field(value, "timestamp"),
      branch_start: parent_id != previous,
      event,
      raw: value,
    })
    previous = id
  }
  Ok({
    agent: Pi,
    id: string_field(header, "id").unwrap_or(""),
    version: 3,
    cwd: string_field(header, "cwd"),
    timestamp: string_field(header, "timestamp"),
    header,
    entries,
    diagnostics,
  })
}

///|
fn pi_event(value : Json, kind : String) -> Event {
  match kind {
    "message" =>
      match field(value, "message") {
        Some(message) => pi_message(message)
        None => Unknown("Invalid message")
      }
    "model_change" => {
      guard string_field(value, "provider") is Some(provider) &&
        string_field(value, "modelId") is Some(model) else {
        return Unknown(kind)
      }
      Notice(title="Model changed", blocks=[Text("\{provider} / \{model}")])
    }
    "thinking_level_change" => {
      guard string_field(value, "thinkingLevel") is Some(level) else {
        return Unknown(kind)
      }
      Notice(title="Thinking level changed", blocks=[Text(level)])
    }
    "compaction" | "branch_summary" => {
      guard string_field(value, "summary") is Some(summary) else {
        return Unknown(kind)
      }
      Notice(
        title=if kind == "compaction" {
          "Context compacted"
        } else {
          "Branch summary"
        },
        blocks=[Text(summary)],
      )
    }
    "custom_message" => {
      let custom_type = string_field(value, "customType").unwrap_or(
        "Custom message",
      )
      let title = if field(value, "display") is Some(False) {
        "\{custom_type} (hidden in agent UI)"
      } else {
        custom_type
      }
      Notice(
        title~,
        blocks=pi_content(field(value, "content").unwrap_or(Json::null())),
      )
    }
    "session_info" => {
      guard string_field(value, "name") is Some(name) else {
        return Unknown(kind)
      }
      Notice(title="Session renamed", blocks=[Text(name)])
    }
    _ => Unknown(kind)
  }
}

///|
fn pi_message(value : Json) -> Event {
  guard string_field(value, "role") is Some(role) &&
    field(value, "content") is Some(content) else {
    return Unknown("Invalid message")
  }
  let role : Role = match role {
    "user" => User
    "assistant" => Assistant
    "system" => System
    "toolResult" => Tool
    other => Custom(other)
  }
  Message({
    role,
    blocks: pi_content(content),
    provider: string_field(value, "provider"),
    model: string_field(value, "model"),
    tool_call_id: string_field(value, "toolCallId"),
    tool_name: string_field(value, "toolName"),
    is_error: bool_field(value, "isError") ||
    string_field(value, "stopReason") == Some("error"),
    stop_reason: string_field(value, "stopReason"),
    error: string_field(value, "errorMessage"),
  })
}

///|
fn pi_content(content : Json) -> Array[Block] {
  match content {
    String(text) => [Text(text)]
    Array(blocks) => blocks.map(pi_block)
    _ => [Unknown(content)]
  }
}

///|
fn pi_block(value : Json) -> Block {
  match string_field(value, "type") {
    Some("text") =>
      match string_field(value, "text") {
        Some(text) => Text(text)
        None => Unknown(value)
      }
    Some("thinking") =>
      match string_field(value, "thinking") {
        Some(text) => Thinking(text)
        None => Unknown(value)
      }
    Some("toolCall") => {
      guard string_field(value, "id") is Some(id) &&
        string_field(value, "name") is Some(name) &&
        field(value, "arguments") is Some(arguments) else {
        return Unknown(value)
      }
      ToolCall(id~, name~, arguments~)
    }
    Some("image") => {
      guard string_field(value, "mimeType") is Some(mime_type) &&
        string_field(value, "data") is Some(data) else {
        return Unknown(value)
      }
      Image(mime_type~, data~)
    }
    _ => Unknown(value)
  }
}
