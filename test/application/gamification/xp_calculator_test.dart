import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/gamification/xp_calculator.dart';

void main() {
  test('correct answers are worth more xp than wrong ones', () {
    final allCorrect = XpCalculator.xpFromReviews(correctCount: 10, totalReviewed: 10);
    final allWrong = XpCalculator.xpFromReviews(correctCount: 0, totalReviewed: 10);

    expect(allCorrect, 100);
    expect(allWrong, 20);
    expect(allCorrect, greaterThan(allWrong));
  });

  test('level starts at 1 and increases every 100 xp', () {
    expect(XpCalculator.levelForXp(0), 1);
    expect(XpCalculator.levelForXp(99), 1);
    expect(XpCalculator.levelForXp(100), 2);
    expect(XpCalculator.levelForXp(250), 3);
  });

  test('xpIntoCurrentLevel wraps around 100', () {
    expect(XpCalculator.xpIntoCurrentLevel(0), 0);
    expect(XpCalculator.xpIntoCurrentLevel(99), 99);
    expect(XpCalculator.xpIntoCurrentLevel(100), 0);
    expect(XpCalculator.xpIntoCurrentLevel(150), 50);
  });
}
