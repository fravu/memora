import '../entities/card_progress.dart' as progress;
import '../entities/vocab.dart';

abstract class CardProgressRepository {
  /// Vokabeln eines Decks, deren Lernstand faellig ist (dueDate <= asOf),
  /// sortiert nach Faelligkeit.
  Stream<List<Vocab>> watchDueVocabs(int deckId, {required DateTime asOf});

  Future<progress.CardProgress> getProgress(int vocabId);

  Future<void> saveProgress(progress.CardProgress progress);
}
