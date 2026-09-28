/// Einfache, bewusst simple XP/Level-Formel (kein Overengineering):
/// richtige Antworten zaehlen mehr als falsche Versuche, Level steigt
/// alle 100 XP.
class XpCalculator {
  static int xpFromReviews({
    required int correctCount,
    required int totalReviewed,
  }) {
    final wrongCount = totalReviewed - correctCount;
    return correctCount * 10 + wrongCount * 2;
  }

  static int levelForXp(int xp) => (xp ~/ 100) + 1;

  /// XP, die im aktuellen Level bereits gesammelt wurden (0-99).
  static int xpIntoCurrentLevel(int xp) => xp % 100;
}
