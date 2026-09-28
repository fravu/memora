import '../../domain/entities/card_progress.dart';
import '../../domain/entities/review_rating.dart';

/// Vereinfachte SM-2-Variante mit 4 Bewertungsstufen (wie Anki):
/// wieder/schwer/gut/leicht statt der klassischen 0-5-Skala.
class SrsScheduler {
  static const double _minEase = 1.3;
  static const double _maxEase = 5.0;
  static const int _maxIntervalDays = 365;

  CardProgress next(
    CardProgress current,
    ReviewRating rating, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();

    double ease = current.easeFactor;
    int repetitions = current.repetitions;
    int intervalDays;

    switch (rating) {
      case ReviewRating.again:
        repetitions = 0;
        ease = _clampEase(ease - 0.2);
        intervalDays = 1;
      case ReviewRating.hard:
        repetitions += 1;
        ease = _clampEase(ease - 0.15);
        intervalDays = repetitions <= 1
            ? 1
            : (current.intervalDays * 1.2).round();
      case ReviewRating.good:
        repetitions += 1;
        intervalDays = switch (repetitions) {
          1 => 1,
          2 => 6,
          _ => (current.intervalDays * ease).round(),
        };
      case ReviewRating.easy:
        repetitions += 1;
        ease = _clampEase(ease + 0.15);
        intervalDays = repetitions == 1
            ? 4
            : ((current.intervalDays == 0 ? 6 : current.intervalDays) *
                    ease *
                    1.3)
                .round();
    }

    intervalDays = intervalDays.clamp(1, _maxIntervalDays);

    return CardProgress(
      id: current.id,
      vocabId: current.vocabId,
      easeFactor: ease,
      intervalDays: intervalDays,
      repetitions: repetitions,
      dueDate: effectiveNow.add(Duration(days: intervalDays)),
      lastReviewedAt: effectiveNow,
    );
  }

  double _clampEase(double ease) => ease.clamp(_minEase, _maxEase);
}
