import '../../domain/entities/review_rating.dart';
import '../../domain/repositories/card_progress_repository.dart';
import '../../domain/repositories/stats_repository.dart';
import '../srs/srs_scheduler.dart';

/// Orchestriert eine einzelne Kartenbewertung: liest den aktuellen
/// Lernstand, berechnet den naechsten Zustand per SM-2, speichert ihn und
/// schreibt die Tages-Statistik (Streak/XP-Basis) fort.
class ReviewVocabUseCase {
  ReviewVocabUseCase(this._repository, this._scheduler, this._statsRepository);

  final CardProgressRepository _repository;
  final SrsScheduler _scheduler;
  final StatsRepository _statsRepository;

  Future<void> call(int vocabId, ReviewRating rating) async {
    final current = await _repository.getProgress(vocabId);
    final next = _scheduler.next(current, rating);
    await _repository.saveProgress(next);
    await _statsRepository.recordReview(wasCorrect: rating != ReviewRating.again);
  }
}
