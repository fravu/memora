import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/gamification/gamification_summary.dart';
import 'package:memora/domain/entities/stats_snapshot.dart';

void main() {
  test('empty history yields a zeroed-out summary at level 1', () {
    final summary = GamificationSummary.fromHistory([]);

    expect(summary.totalReviewed, 0);
    expect(summary.totalCorrect, 0);
    expect(summary.currentStreak, 0);
    expect(summary.xp, 0);
    expect(summary.level, 1);
    expect(summary.accuracy, 0);
  });

  test('aggregates totals and uses the latest day for the streak', () {
    final history = [
      StatsSnapshot(
        id: 1,
        date: DateTime(2026, 1, 1),
        cardsReviewed: 5,
        correctCount: 4,
        streakDay: 1,
      ),
      StatsSnapshot(
        id: 2,
        date: DateTime(2026, 1, 2),
        cardsReviewed: 3,
        correctCount: 3,
        streakDay: 2,
      ),
    ];

    final summary = GamificationSummary.fromHistory(history);

    expect(summary.totalReviewed, 8);
    expect(summary.totalCorrect, 7);
    expect(summary.currentStreak, 2);
    expect(summary.accuracy, closeTo(7 / 8, 0.001));
  });
}
