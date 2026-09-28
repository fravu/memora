import 'package:drift/drift.dart';

import '../../domain/entities/stats_snapshot.dart' as domain;
import '../../domain/repositories/stats_repository.dart';
import '../drift/database.dart';

class DriftStatsRepository implements StatsRepository {
  DriftStatsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> recordReview({required bool wasCorrect}) async {
    final today = _dateOnly(DateTime.now());
    final existing = await (_db.select(_db.statsSnapshots)
          ..where((s) => s.date.equals(today)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.statsSnapshots)
            ..where((s) => s.id.equals(existing.id)))
          .write(
        StatsSnapshotsCompanion(
          cardsReviewed: Value(existing.cardsReviewed + 1),
          correctCount:
              Value(existing.correctCount + (wasCorrect ? 1 : 0)),
        ),
      );
      return;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdaySnapshot = await (_db.select(_db.statsSnapshots)
          ..where((s) => s.date.equals(yesterday)))
        .getSingleOrNull();
    final newStreak = (yesterdaySnapshot?.streakDay ?? 0) + 1;

    await _db.into(_db.statsSnapshots).insert(
          StatsSnapshotsCompanion.insert(
            date: today,
            cardsReviewed: const Value(1),
            correctCount: Value(wasCorrect ? 1 : 0),
            streakDay: Value(newStreak),
          ),
        );
  }

  @override
  Stream<List<domain.StatsSnapshot>> watchHistory({int days = 365}) {
    final since = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    return (_db.select(_db.statsSnapshots)
          ..where((s) => s.date.isBiggerOrEqualValue(since))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  domain.StatsSnapshot _toEntity(StatsSnapshot row) => domain.StatsSnapshot(
        id: row.id,
        date: row.date,
        cardsReviewed: row.cardsReviewed,
        correctCount: row.correctCount,
        streakDay: row.streakDay,
      );
}
