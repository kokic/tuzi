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

///|
fn entry_size_view(entry : Entry) -> Html {
  let style = entry_meta_style() +
    [
      "grid-column: 2", "text-align: right", "font-variant-numeric: tabular-nums",
    ]
  guard !entry.is_dir else { return span(style~, "") }
  guard entry.size is Some(size) else {
    return span(style~, title="Unknown size", "Unknown size")
  }
  let formatted = format_file_size(size)
  let unit_offset = formatted.length() - 1
  span(style~, title=formatted, [
    span("\{formatted[:unit_offset]}"),
    span(
      style=["display: inline-block", "width: 1em", "text-align: left"],
      "\{formatted[unit_offset:]}",
    ),
  ])
}

///|
fn entry_time_view(entry : Entry) -> Html {
  let style = entry_meta_style() +
    [
      "grid-column: 3", "text-align: right", "font-variant-numeric: tabular-nums",
    ]
  guard entry.mtime is Some(time) else { return span(style~, "") }
  let formatted = format_timestamp(time)
  // The year can have more than four digits; MM-DD and HH:MM have fixed lengths.
  let date_end = formatted.length() - 6
  let month_start = date_end - 5
  span(style~, title=formatted, [
    span(class="entry-time-year", "\{formatted[:month_start]}"),
    span("\{formatted[month_start:date_end]}"),
    span(class="entry-time-clock", "\{formatted[date_end:]}"),
  ])
}
