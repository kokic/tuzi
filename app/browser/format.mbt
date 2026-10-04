///|
let unknown_size : @tuzi.FormattedFileSize = { value: "???", unit: "B", }

///|
fn format_entry_meta(entry : Entry) -> String {
  let parts = [
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
fn entry_size_view(entry : Entry) -> Html {
  let style = entry_meta_style() +
    [
      "grid-column: 2 / 4", "display: grid", "grid-template-columns: subgrid", "column-gap: 0",
      "text-align: right", "font-variant-numeric: tabular-nums",
    ]
  guard !entry.is_dir() else { span(style~, "") }
  guard entry.size is Ok(size) else {
    span(style~, title=entry.size.unwrap_err().message, "Unavailable")
  }
  let formatted = size.map_or(unknown_size, size => format_file_size(size))
  span(style~, title=formatted.to_string(), [
    span(formatted.value),
    span(style=["text-align: left"], formatted.unit),
  ])
}

///|
fn entry_time_view(entry : Entry) -> Html {
  let style = entry_meta_style() +
    [
      "grid-column: 4", "text-align: right", "font-variant-numeric: tabular-nums",
    ]
  guard entry.mtime is Ok(time) else {
    span(style~, title=entry.mtime.unwrap_err().message, "Unavailable")
  }
  let formatted = format_timestamp(time)
  span(style~, title=formatted.to_string(), [
    span(class="entry-time-year", formatted.year + "-"),
    span(formatted.month_day),
    span(class="entry-time-clock", " " + formatted.clock),
  ])
}
