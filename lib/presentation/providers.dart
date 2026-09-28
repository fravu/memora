import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/srs/srs_scheduler.dart';
import '../application/usecases/review_vocab_usecase.dart';
import '../data/drift/database.dart' show AppDatabase;
import '../data/repositories_impl/drift_card_progress_repository.dart';
import '../data/repositories_impl/drift_deck_repository.dart';
import '../data/repositories_impl/drift_vocab_repository.dart';
import '../domain/entities/deck.dart';
import '../domain/entities/vocab.dart';
import '../domain/repositories/card_progress_repository.dart';
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

final cardProgressRepositoryProvider = Provider<CardProgressRepository>((ref) {
  return DriftCardProgressRepository(ref.watch(appDatabaseProvider));
});

final srsSchedulerProvider = Provider<SrsScheduler>((ref) => SrsScheduler());

final reviewVocabUseCaseProvider = Provider<ReviewVocabUseCase>((ref) {
  return ReviewVocabUseCase(
    ref.watch(cardProgressRepositoryProvider),
    ref.watch(srsSchedulerProvider),
  );
});

final dueVocabsForDeckProvider =
    StreamProvider.family<List<Vocab>, int>((ref, deckId) {
  return ref
      .watch(cardProgressRepositoryProvider)
      .watchDueVocabs(deckId, asOf: DateTime.now());
});
