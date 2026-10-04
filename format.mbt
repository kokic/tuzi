///|
pub(all) struct FormattedFileSize {
  value : String
  unit : String
}

///|
pub impl Show for FormattedFileSize with fn output(self, logger) {
  logger.write_string(self.value)
  logger.write_string(self.unit)
}

///|
pub extend FormattedFileSize with Show::{to_string, output}

///|
/// Format the value and unit separately (base 1024, truncated).
pub fn format_file_size(size : Int64) -> FormattedFileSize {
  let units = ["B", "K", "M", "G", "T"]
  let (scale, i) = for scale = 1L, i = 0 {
    let can_scale_up = size >= scale * 1024L && i + 1 < units.length()
    guard can_scale_up else { break (scale, i) }
    continue scale * 1024L, i + 1
  }
  let whole = size / scale
  let frac = size % scale * 10L / scale
  let value = if frac == 0L { "\{whole}" } else { "\{whole}.\{frac}" }
  { value, unit: units[i], }
}

///|
/// UTC display components; text is assembled only at the output boundary.
pub(all) struct FormattedTimestamp {
  year : String
  month_day : String
  clock : String
}

///|
pub impl Show for FormattedTimestamp with fn output(self, logger) {
  logger.write_string(self.year)
  logger.write_string("-")
  logger.write_string(self.month_day)
  logger.write_string(" ")
  logger.write_string(self.clock)
}

///|
pub extend FormattedTimestamp with Show::{to_string, output}

///|
/// Format a Unix timestamp in UTC, optionally including seconds.
pub fn format_timestamp(
  sec : Int64,
  seconds? : Bool = false,
) -> FormattedTimestamp {
  let days = floor_divide(sec, 86400L)
  let rem = sec - days * 86400L
  let hour = rem / 3600L
  let minute = rem % 3600L / 60L
  let (y, m, day) = calendar_date_from_epoch_days(days)
  let clock = "\{format_two_digits(hour)}:\{format_two_digits(minute)}"
  {
    year: y.to_string(),
    month_day: "\{format_two_digits(m)}-\{format_two_digits(day)}",
    clock: if seconds {
      clock + ":" + format_two_digits(rem % 60L)
    } else {
      clock
    },
  }
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
  let m = if mp < 10L { mp + 3L } else { mp - 9L }
  let y = if m > 2L { y } else { y + 1L }
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
