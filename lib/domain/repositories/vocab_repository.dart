import '../entities/vocab.dart';

abstract class VocabRepository {
  Stream<List<Vocab>> watchVocabsForDeck(int deckId);

  Future<int> addVocab({
    required int deckId,
    required String term,
    required String translation,
    String? exampleSentence,
  });

  Future<void> updateVocab(Vocab vocab);

  Future<void> deleteVocab(int id);

  /// Fuegt mehrere Vokabeln in einer einzigen Transaktion ein (z.B. fuer
  /// CSV-Import) statt jede einzeln zu committen.
  Future<void> addVocabsBatch(
    int deckId,
    List<({String term, String translation, String? exampleSentence})> entries,
  );
}
