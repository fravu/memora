import '../entities/deck.dart';

abstract class DeckRepository {
  Stream<List<Deck>> watchDecks();

  Future<int> createDeck({
    required String name,
    required String sourceLang,
    required String targetLang,
  });

  Future<void> renameDeck(int id, String newName);

  Future<void> deleteDeck(int id);
}
