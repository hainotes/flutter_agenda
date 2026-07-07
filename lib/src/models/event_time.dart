/// A time-of-day value used for event starts/ends and tap positions.
///
/// Extends [DateTime] anchored to a fixed reference date (2000-01-01) so that
/// instances created on different calendar days still compare consistently
/// with each other. Only [hour] and [minute] are meaningful; the date
/// components carry no semantics.
class EventTime extends DateTime {
  final int hour;

  final int minute;

  EventTime({
    required this.hour,
    required this.minute,
  })  : assert(hour >= 0 && hour < 24, 'hour must be in [0, 23]'),
        assert(minute >= 0 && minute < 60, 'minute must be in [0, 59]'),
        super(2000, 1, 1, hour, minute);
}
