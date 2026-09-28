import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/data/repositories_impl/drift_stats_repository.dart';

void main() {
  late AppDatabase db;
  late DriftStatsRepository statsRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    statsRepo = DriftStatsRepository(db);
  });

  tearDown(() => db.close());

  test('first review of the day starts a streak of 1', () async {
    await statsRepo.recordReview(wasCorrect: true);

    final history = await statsRepo.watchHistory().first;
    expect(history.single.streakDay, 1);
    expect(history.single.cardsReviewed, 1);
    expect(history.single.correctCount, 1);
  });

  test('a second review on the same day increments counts without duplicating rows', () async {
    await statsRepo.recordReview(wasCorrect: true);
    await statsRepo.recordReview(wasCorrect: false);

    final history = await statsRepo.watchHistory().first;
    expect(history, hasLength(1));
    expect(history.single.cardsReviewed, 2);
    expect(history.single.correctCount, 1);
  });

  test('continues the streak when yesterday already has an entry', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);
    await db.into(db.statsSnapshots).insert(
          StatsSnapshotsCompanion.insert(
            date: dateOnly,
            cardsReviewed: const Value(3),
            correctCount: const Value(3),
            streakDay: const Value(5),
          ),
        );

    await statsRepo.recordReview(wasCorrect: true);

    final history = await statsRepo.watchHistory().first;
    final today = history.last;
    expect(today.streakDay, 6);
  });

  test('starts a new streak when yesterday has no entry', () async {
    final longAgo = DateTime.now().subtract(const Duration(days: 10));
    final dateOnly = DateTime(longAgo.year, longAgo.month, longAgo.day);
    await db.into(db.statsSnapshots).insert(
          StatsSnapshotsCompanion.insert(
            date: dateOnly,
            cardsReviewed: const Value(3),
            correctCount: const Value(3),
            streakDay: const Value(9),
          ),
        );

    await statsRepo.recordReview(wasCorrect: true);

    final history = await statsRepo.watchHistory().first;
    final today = history.last;
    expect(today.streakDay, 1);
  });
}
