import '../../domain/entities/stats_snapshot.dart';
import 'xp_calculator.dart';

class GamificationSummary {
  const GamificationSummary({
    required this.totalReviewed,
    required this.totalCorrect,
    required this.currentStreak,
    required this.xp,
    required this.level,
  });

  final int totalReviewed;
  final int totalCorrect;
  final int currentStreak;
  final int xp;
  final int level;

  double get accuracy => totalReviewed == 0 ? 0 : totalCorrect / totalReviewed;

  /// [history] muss aufsteigend nach Datum sortiert sein.
  factory GamificationSummary.fromHistory(List<StatsSnapshot> history) {
    if (history.isEmpty) {
      return const GamificationSummary(
        totalReviewed: 0,
        totalCorrect: 0,
        currentStreak: 0,
        xp: 0,
        level: 1,
      );
    }

    var totalReviewed = 0;
    var totalCorrect = 0;
    for (final snapshot in history) {
      totalReviewed += snapshot.cardsReviewed;
      totalCorrect += snapshot.correctCount;
    }

    final xp = XpCalculator.xpFromReviews(
      correctCount: totalCorrect,
      totalReviewed: totalReviewed,
    );

    return GamificationSummary(
      totalReviewed: totalReviewed,
      totalCorrect: totalCorrect,
      currentStreak: history.last.streakDay,
      xp: xp,
      level: XpCalculator.levelForXp(xp),
    );
  }
}
