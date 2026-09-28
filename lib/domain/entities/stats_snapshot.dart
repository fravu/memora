class StatsSnapshot {
  const StatsSnapshot({
    required this.id,
    required this.date,
    required this.cardsReviewed,
    required this.correctCount,
    required this.streakDay,
  });

  final int id;
  final DateTime date;
  final int cardsReviewed;
  final int correctCount;
  final int streakDay;
}
