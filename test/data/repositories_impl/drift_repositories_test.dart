import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/data/repositories_impl/drift_deck_repository.dart';
import 'package:memora/data/repositories_impl/drift_vocab_repository.dart';

void main() {
  late AppDatabase db;
  late DriftDeckRepository deckRepo;
  late DriftVocabRepository vocabRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    deckRepo = DriftDeckRepository(db);
    vocabRepo = DriftVocabRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addVocab legt automatisch einen Lernstand an', () async {
    final deckId = await deckRepo.createDeck(
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
    );
    final vocabId = await vocabRepo.addVocab(
      deckId: deckId,
      term: 'Hallo',
      translation: 'hello',
    );

    final progress = await db.select(db.cardProgresses).getSingle();
    expect(progress.vocabId, vocabId);
    expect(progress.easeFactor, 2.5);
  });

  test('deleteDeck kaskadiert auf Vokabeln und Lernstand', () async {
    final deckId = await deckRepo.createDeck(
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
    );
    await vocabRepo.addVocab(
      deckId: deckId,
      term: 'Hallo',
      translation: 'hello',
    );

    await deckRepo.deleteDeck(deckId);

    final vocabs = await db.select(db.vocabs).get();
    final progresses = await db.select(db.cardProgresses).get();
    expect(vocabs, isEmpty);
    expect(progresses, isEmpty);
  });

  test('renameDeck aktualisiert den Namen', () async {
    final deckId = await deckRepo.createDeck(
      name: 'Alt',
      sourceLang: 'de',
      targetLang: 'en',
    );

    await deckRepo.renameDeck(deckId, 'Neu');

    final decks = await db.select(db.decks).get();
    expect(decks.single.name, 'Neu');
  });
}
