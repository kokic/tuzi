///|
using @rabbita {type Html}

///|
using @html {span}

///|
let unknown_size : FormattedFileSize = { value: "???", unit: "B", }

///|
pub fn format_entry_meta(entry : Entry) -> String {
  let parts = [
    ..if entry.kind is Err(error) {
      ["Type unavailable: " + error.message]
    },
    match entry.mtime {
      Ok(time) => format_timestamp(time).to_string()
      Err(error) => "Modified time unavailable: " + error.message
    },
    ..if !entry.is_dir() {
      [
        match entry.size {
          Ok(size) =>
            size
            .map_or(unknown_size, size => format_file_size(size))
            .to_string()
          Err(error) => "Size unavailable: " + error.message
        },
      ]
    },
  ]
  parts.filter(part => !part.is_empty()).join(" ")
}

///|
pub fn entry_size_view(entry : Entry) -> Html {
  let style = ["grid-column: 2", "text-align: right"]
  let text = if entry.is_dir() {
    match entry.child_count {
      None => "…"
      Some(Err(_)) => "Unavailable"
      Some(Ok(count)) => "\{count} items"
    }
  } else {
    match entry.size {
      Ok(size) =>
        size.map_or(unknown_size, size => format_file_size(size)).to_string()
      Err(_) => "Unavailable"
    }
  }
  span(class="entry-meta", style~, text)
}

///|
pub fn entry_time_view(entry : Entry) -> Html {
  let style = ["grid-column: 3", "text-align: right"]
  guard entry.mtime is Ok(time) else {
    span(class="entry-meta", style~, "Unavailable")
  }
  let formatted = format_timestamp(time)
  span(class="entry-meta", style~, [
    span(class="entry-time-year", formatted.year + "-"),
    span(formatted.month_day),
    span(class="entry-time-clock", " " + formatted.clock),
  ])
}
