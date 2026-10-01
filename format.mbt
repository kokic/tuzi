///|
/// Format a file size as `512B`, `1.5M`, `2.3G`, ... (base 1024, truncated).
pub fn format_file_size(size : Int64) -> String {
  let units = ["B", "K", "M", "G", "T"]
  let (scale, i) = for scale = 1L, i = 0 {
    let can_scale_up = size >= scale * 1024L && i + 1 < units.length()
    guard can_scale_up else { break (scale, i) }
    continue scale * 1024L, i + 1
  }
  let whole = size / scale
  let frac = size % scale * 10L / scale
  guard frac == 0L else { "\{whole}.\{frac}\{units[i]}" }
  "\{whole}\{units[i]}"
}

///|
/// Format a Unix timestamp in UTC, optionally including seconds.
pub fn format_timestamp(sec : Int64, seconds? : Bool = false) -> String {
  let days = floor_divide(sec, 86400L)
  let rem = sec - days * 86400L
  let hour = rem / 3600L
  let minute = rem % 3600L / 60L
  let (y, m, day) = calendar_date_from_epoch_days(days)
  let timestamp = "\{y}-\{format_two_digits(m)}-\{format_two_digits(day)} \{format_two_digits(hour)}:\{format_two_digits(minute)}"
  guard seconds else { return timestamp }
  timestamp + ":" + format_two_digits(rem % 60L)
}

///|
fn format_two_digits(n : Int64) -> String {
  guard n < 10L else { "\{n}" }
  "0\{n}"
}

///|
/// Howard Hinnant's civil-from-days algorithm (proleptic Gregorian, UTC).
/// `days` is the number of days since the Unix epoch.
fn calendar_date_from_epoch_days(days : Int64) -> (Int64, Int64, Int64) {
  let z = days + 719468L
  let era = floor_divide(z, 146097L)
  let doe = z - era * 146097L
  let yoe = floor_divide(
    doe -
    floor_divide(doe, 1460L) +
    floor_divide(doe, 36524L) -
    floor_divide(doe, 146096L),
    365L,
  )
  let y = yoe + era * 400L
  let doy = doe - (365L * yoe + floor_divide(yoe, 4L) - floor_divide(yoe, 100L))
  let mp = floor_divide(5L * doy + 2L, 153L)
  let day = doy - floor_divide(153L * mp + 2L, 5L) + 1L
  let m = {
    guard mp < 10L else { mp - 9L }
    mp + 3L
  }
  let y = {
    guard m > 2L else { y + 1L }
    y
  }
  (y, m, day)
}

///|
/// Euclidean-like division that floors toward negative infinity.
fn floor_divide(a : Int64, b : Int64) -> Int64 {
  let q = a / b
  let signs_differ = (a < 0L) != (b < 0L)
  guard !(a % b != 0L && signs_differ) else { q - 1L }
  q
}
