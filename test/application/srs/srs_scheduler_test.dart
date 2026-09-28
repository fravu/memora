import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/srs/srs_scheduler.dart';
import 'package:memora/domain/entities/card_progress.dart';
import 'package:memora/domain/entities/review_rating.dart';

void main() {
  final scheduler = SrsScheduler();
  final now = DateTime(2026, 1, 1);

  CardProgress freshCard({
    double easeFactor = 2.5,
    int intervalDays = 0,
    int repetitions = 0,
  }) {
    return CardProgress(
      id: 1,
      vocabId: 1,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
      dueDate: now,
    );
  }

  group('good rating', () {
    test('first "good" schedules 1 day out and increments repetitions', () {
      final next = scheduler.next(freshCard(), ReviewRating.good, now: now);

      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.dueDate, now.add(const Duration(days: 1)));
    });

    test('second consecutive "good" schedules 6 days out', () {
      final afterFirst = scheduler.next(freshCard(), ReviewRating.good, now: now);
      final afterSecond = scheduler.next(afterFirst, ReviewRating.good, now: now);

      expect(afterSecond.repetitions, 2);
      expect(afterSecond.intervalDays, 6);
    });

    test('third+ "good" grows interval by the ease factor', () {
      var progress = freshCard();
      progress = scheduler.next(progress, ReviewRating.good, now: now); // rep 1
      progress = scheduler.next(progress, ReviewRating.good, now: now); // rep 2, interval 6
      final third = scheduler.next(progress, ReviewRating.good, now: now);

      expect(third.repetitions, 3);
      expect(third.intervalDays, (6 * progress.easeFactor).round());
    });

    test('does not change the ease factor', () {
      final next = scheduler.next(freshCard(), ReviewRating.good, now: now);
      expect(next.easeFactor, 2.5);
    });
  });

  group('again rating', () {
    test('resets repetitions and shrinks the interval to 1 day', () {
      final progressed = freshCard(intervalDays: 30, repetitions: 4);
      final next = scheduler.next(progressed, ReviewRating.again, now: now);

      expect(next.repetitions, 0);
      expect(next.intervalDays, 1);
    });

    test('lowers the ease factor by 0.2', () {
      final next = scheduler.next(freshCard(), ReviewRating.again, now: now);
      expect(next.easeFactor, closeTo(2.3, 0.001));
    });

    test('ease factor never drops below 1.3', () {
      var progress = freshCard(easeFactor: 1.35);
      progress = scheduler.next(progress, ReviewRating.again, now: now);
      progress = scheduler.next(progress, ReviewRating.again, now: now);

      expect(progress.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });

  group('hard rating', () {
    test('lowers the ease factor by 0.15', () {
      final next = scheduler.next(freshCard(), ReviewRating.hard, now: now);
      expect(next.easeFactor, closeTo(2.35, 0.001));
    });

    test('grows the interval more slowly than "good"', () {
      var goodProgress = freshCard(intervalDays: 10, repetitions: 2, easeFactor: 2.5);
      var hardProgress = freshCard(intervalDays: 10, repetitions: 2, easeFactor: 2.5);

      final goodNext = scheduler.next(goodProgress, ReviewRating.good, now: now);
      final hardNext = scheduler.next(hardProgress, ReviewRating.hard, now: now);

      expect(hardNext.intervalDays, lessThan(goodNext.intervalDays));
    });
  });

  group('easy rating', () {
    test('raises the ease factor by 0.15', () {
      final next = scheduler.next(freshCard(), ReviewRating.easy, now: now);
      expect(next.easeFactor, closeTo(2.65, 0.001));
    });

    test('grows the interval faster than "good"', () {
      var goodProgress = freshCard(intervalDays: 10, repetitions: 2, easeFactor: 2.5);
      var easyProgress = freshCard(intervalDays: 10, repetitions: 2, easeFactor: 2.5);

      final goodNext = scheduler.next(goodProgress, ReviewRating.good, now: now);
      final easyNext = scheduler.next(easyProgress, ReviewRating.easy, now: now);

      expect(easyNext.intervalDays, greaterThan(goodNext.intervalDays));
    });

    test('ease factor never exceeds 5.0', () {
      var progress = freshCard(easeFactor: 4.95);
      progress = scheduler.next(progress, ReviewRating.easy, now: now);
      progress = scheduler.next(progress, ReviewRating.easy, now: now);

      expect(progress.easeFactor, lessThanOrEqualTo(5.0));
    });
  });

  test('interval is always clamped between 1 and 365 days', () {
    final hugeProgress = freshCard(intervalDays: 1000, repetitions: 10, easeFactor: 5.0);
    final next = scheduler.next(hugeProgress, ReviewRating.easy, now: now);

    expect(next.intervalDays, lessThanOrEqualTo(365));
    expect(next.intervalDays, greaterThanOrEqualTo(1));
  });

  test('sets lastReviewedAt to the review time', () {
    final next = scheduler.next(freshCard(), ReviewRating.good, now: now);
    expect(next.lastReviewedAt, now);
  });
}
