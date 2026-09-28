import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/srs/srs_scheduler.dart';
import 'package:memora/application/usecases/review_vocab_usecase.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/data/repositories_impl/drift_card_progress_repository.dart';
import 'package:memora/data/repositories_impl/drift_deck_repository.dart';
import 'package:memora/data/repositories_impl/drift_vocab_repository.dart';
import 'package:memora/domain/entities/card_progress.dart';
import 'package:memora/domain/entities/review_rating.dart';

void main() {
  late AppDatabase db;
  late DriftDeckRepository deckRepo;
  late DriftVocabRepository vocabRepo;
  late DriftCardProgressRepository progressRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    deckRepo = DriftDeckRepository(db);
    vocabRepo = DriftVocabRepository(db);
    progressRepo = DriftCardProgressRepository(db);
  });

  tearDown(() => db.close());

  test('watchDueVocabs only returns cards due at or before asOf', () async {
    final deckId = await deckRepo.createDeck(
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
    );
    await vocabRepo.addVocab(deckId: deckId, term: 'Haus', translation: 'house');
    final futureVocabId = await vocabRepo.addVocab(
      deckId: deckId,
      term: 'Baum',
      translation: 'tree',
    );

    // "Baum" wird kuenstlich weit in die Zukunft verschoben, damit er nicht
    // faellig ist.
    final futureProgress = await progressRepo.getProgress(futureVocabId);
    await progressRepo.saveProgress(
      CardProgress(
        id: futureProgress.id,
        vocabId: futureProgress.vocabId,
        easeFactor: futureProgress.easeFactor,
        intervalDays: futureProgress.intervalDays,
        repetitions: futureProgress.repetitions,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        lastReviewedAt: futureProgress.lastReviewedAt,
      ),
    );

    final due = await progressRepo
        .watchDueVocabs(deckId, asOf: DateTime.now())
        .first;

    expect(due.map((v) => v.term), ['Haus']);
  });

  test('ReviewVocabUseCase updates the progress via the scheduler', () async {
    final deckId = await deckRepo.createDeck(
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
    );
    final vocabId = await vocabRepo.addVocab(
      deckId: deckId,
      term: 'Haus',
      translation: 'house',
    );

    final useCase = ReviewVocabUseCase(progressRepo, SrsScheduler());
    await useCase.call(vocabId, ReviewRating.good);

    final progress = await progressRepo.getProgress(vocabId);
    expect(progress.repetitions, 1);
    expect(progress.intervalDays, 1);
    expect(progress.lastReviewedAt, isNotNull);
  });
}
