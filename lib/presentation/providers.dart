import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/drift/database.dart' show AppDatabase;
import '../data/repositories_impl/drift_deck_repository.dart';
import '../data/repositories_impl/drift_vocab_repository.dart';
import '../domain/entities/deck.dart';
import '../domain/entities/vocab.dart';
import '../domain/repositories/deck_repository.dart';
import '../domain/repositories/vocab_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DriftDeckRepository(ref.watch(appDatabaseProvider));
});

final vocabRepositoryProvider = Provider<VocabRepository>((ref) {
  return DriftVocabRepository(ref.watch(appDatabaseProvider));
});

final decksProvider = StreamProvider<List<Deck>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDecks();
});

final vocabsForDeckProvider =
    StreamProvider.family<List<Vocab>, int>((ref, deckId) {
  return ref.watch(vocabRepositoryProvider).watchVocabsForDeck(deckId);
});
