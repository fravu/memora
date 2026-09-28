import '../entities/stats_snapshot.dart';

abstract class StatsRepository {
  /// Erhoeht den heutigen Snapshot (oder legt ihn an) und berechnet dabei
  /// den Streak-Zaehler auf Basis des Vortags.
  Future<void> recordReview({required bool wasCorrect});

  /// Aufsteigend nach Datum sortierter Verlauf der letzten [days] Tage.
  Stream<List<StatsSnapshot>> watchHistory({int days = 365});
}
