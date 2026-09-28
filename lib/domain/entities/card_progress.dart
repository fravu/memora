class CardProgress {
  const CardProgress({
    required this.id,
    required this.vocabId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
    this.lastReviewedAt,
  });

  final int id;
  final int vocabId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final DateTime? lastReviewedAt;
}
