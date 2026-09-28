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
}
