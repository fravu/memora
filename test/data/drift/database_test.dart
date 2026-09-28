import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/data/drift/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('creates a deck, vocab and card progress', () async {
    final deckId = await db.into(db.decks).insert(
          DecksCompanion.insert(
            name: 'Englisch Basics',
            sourceLang: 'de',
            targetLang: 'en',
          ),
        );

    final vocabId = await db.into(db.vocabs).insert(
          VocabsCompanion.insert(
            deckId: deckId,
            term: 'Haus',
            translation: 'house',
          ),
        );

    await db.into(db.cardProgresses).insert(
          CardProgressesCompanion.insert(vocabId: vocabId),
        );

    final decks = await db.select(db.decks).get();
    final vocabs = await db.select(db.vocabs).get();
    final progress = await db.select(db.cardProgresses).getSingle();

    expect(decks, hasLength(1));
    expect(vocabs, hasLength(1));
    expect(vocabs.single.translation, 'house');
    expect(progress.easeFactor, 2.5);
    expect(progress.repetitions, 0);
  });

  test('due date defaults to creation time until reviewed', () async {
    final deckId = await db.into(db.decks).insert(
          DecksCompanion.insert(
            name: 'Test Deck',
            sourceLang: 'de',
            targetLang: 'en',
          ),
        );
    final vocabId = await db.into(db.vocabs).insert(
          VocabsCompanion.insert(
            deckId: deckId,
            term: 'Katze',
            translation: 'cat',
          ),
        );
    await db.into(db.cardProgresses).insert(
          CardProgressesCompanion.insert(vocabId: vocabId),
        );

    final progress = await db.select(db.cardProgresses).getSingle();

    expect(progress.lastReviewedAt, isNull);
    expect(progress.intervalDays, 0);
  });
}
