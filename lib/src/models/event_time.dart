class EventTime extends DateTime {
  final int hour;

  final int minute;

  EventTime({
    required this.hour,
    required this.minute,
  })  : assert(hour >= 0 && hour < 24, 'hour must be in [0, 23]'),
        assert(minute >= 0 && minute < 60, 'minute must be in [0, 59]'),
        super(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          hour,
          minute,
        );
}
