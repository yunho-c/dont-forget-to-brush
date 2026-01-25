class WeeklyStat {
  const WeeklyStat({
    required this.day,
    required this.completed,
    required this.minutes,
  });

  final String day;
  final bool completed;
  final double minutes;
}

const List<WeeklyStat> mockWeeklyStats = [
  WeeklyStat(day: 'Mon', completed: true, minutes: 2.0),
  WeeklyStat(day: 'Tue', completed: true, minutes: 2.5),
  WeeklyStat(day: 'Wed', completed: false, minutes: 0.5),
  WeeklyStat(day: 'Thu', completed: true, minutes: 1.8),
  WeeklyStat(day: 'Fri', completed: true, minutes: 2.1),
  WeeklyStat(day: 'Sat', completed: true, minutes: 3.0),
  WeeklyStat(day: 'Sun', completed: false, minutes: 0.0),
];

const List<String> motivationalQuotes = [
  'Quick brush = done for the night.',
  'Brush now so Future You can sleep.',
  "Let's get this done fast.",
  'Protect that streak!',
  'Clean teeth, clear mind.',
];
