import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/gamification/gamification_summary.dart';
import '../application/srs/srs_scheduler.dart';
import '../application/usecases/review_vocab_usecase.dart';
import '../data/drift/database.dart' show AppDatabase;
import '../data/repositories_impl/drift_card_progress_repository.dart';
import '../data/repositories_impl/drift_deck_repository.dart';
import '../data/repositories_impl/drift_stats_repository.dart';
import '../data/repositories_impl/drift_vocab_repository.dart';
import '../data/repositories_impl/shared_prefs_settings_repository.dart';
import '../domain/entities/deck.dart';
import '../domain/entities/stats_snapshot.dart';
import '../domain/entities/vocab.dart';
import '../domain/repositories/card_progress_repository.dart';
import '../domain/repositories/deck_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/stats_repository.dart';
import '../domain/repositories/vocab_repository.dart';
import '../infrastructure/notifications/local_notification_service.dart';
import '../infrastructure/notifications/notification_service.dart';
import '../infrastructure/translation/my_memory_translation_service.dart';
import '../infrastructure/translation/translation_service.dart';
import '../infrastructure/tts/flutter_tts_service.dart';
import '../infrastructure/tts/tts_service.dart';

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

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return DriftStatsRepository(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPrefsSettingsRepository();
});

final ttsServiceProvider = Provider<TtsService>((ref) => FlutterTtsService());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final srsSchedulerProvider = Provider<SrsScheduler>((ref) => SrsScheduler());

final reviewVocabUseCaseProvider = Provider<ReviewVocabUseCase>((ref) {
  return ReviewVocabUseCase(
    ref.watch(cardProgressRepositoryProvider),
    ref.watch(srsSchedulerProvider),
    ref.watch(statsRepositoryProvider),
  );
});

// autoDispose sorgt dafuer, dass beim erneuten Betreten des Review-Screens
// ein frischer "asOf"-Zeitpunkt erfasst wird, statt ihn fuer die gesamte
// App-Laufzeit einzufrieren (siehe Decision Log).
final dueVocabsForDeckProvider =
    StreamProvider.autoDispose.family<List<Vocab>, int>((ref, deckId) {
  return ref
      .watch(cardProgressRepositoryProvider)
      .watchDueVocabs(deckId, asOf: DateTime.now());
});

final statsHistoryProvider = StreamProvider<List<StatsSnapshot>>((ref) {
  return ref.watch(statsRepositoryProvider).watchHistory();
});

final gamificationSummaryProvider = Provider<AsyncValue<GamificationSummary>>((ref) {
  final history = ref.watch(statsHistoryProvider);
  return history.whenData(GamificationSummary.fromHistory);
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).hasCompletedOnboarding();
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  return MyMemoryTranslationService();
});
