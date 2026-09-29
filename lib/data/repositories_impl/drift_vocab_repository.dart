import 'package:drift/drift.dart';

import '../../domain/entities/vocab.dart' as domain;
import '../../domain/repositories/vocab_repository.dart';
import '../drift/database.dart';

class DriftVocabRepository implements VocabRepository {
  DriftVocabRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain.Vocab>> watchVocabsForDeck(int deckId) {
    return (_db.select(_db.vocabs)..where((v) => v.deckId.equals(deckId)))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<int> addVocab({
    required int deckId,
    required String term,
    required String translation,
    String? exampleSentence,
  }) {
    return _insertVocabWithProgress(
      deckId: deckId,
      term: term,
      translation: translation,
      exampleSentence: exampleSentence,
    );
  }

  @override
  Future<void> addVocabsBatch(
    int deckId,
    List<({String term, String translation, String? exampleSentence})> entries,
  ) {
    // Eine Transaktion statt N Einzel-Commits: schneller bei grossen
    // Imports und atomar (entweder alle Zeilen landen in der DB oder keine).
    return _db.transaction(() async {
      for (final entry in entries) {
        await _insertVocabWithProgress(
          deckId: deckId,
          term: entry.term,
          translation: entry.translation,
          exampleSentence: entry.exampleSentence,
        );
      }
    });
  }

  Future<int> _insertVocabWithProgress({
    required int deckId,
    required String term,
    required String translation,
    String? exampleSentence,
  }) async {
    final vocabId = await _db.into(_db.vocabs).insert(
          VocabsCompanion.insert(
            deckId: deckId,
            term: term,
            translation: translation,
            exampleSentence: Value(exampleSentence),
          ),
        );
    // Jede Vokabel bekommt sofort einen Lernstand, damit sie in Phase 2
    // (SRS-Abfrage) ohne Migration auftauchen kann.
    await _db.into(_db.cardProgresses).insert(
          CardProgressesCompanion.insert(vocabId: vocabId),
        );
    return vocabId;
  }

  @override
  Future<void> updateVocab(domain.Vocab vocab) {
    return (_db.update(_db.vocabs)..where((v) => v.id.equals(vocab.id))).write(
      VocabsCompanion(
        term: Value(vocab.term),
        translation: Value(vocab.translation),
        exampleSentence: Value(vocab.exampleSentence),
      ),
    );
  }

  @override
  Future<void> deleteVocab(int id) {
    return (_db.delete(_db.vocabs)..where((v) => v.id.equals(id))).go();
  }

  domain.Vocab _toEntity(Vocab row) => domain.Vocab(
        id: row.id,
        deckId: row.deckId,
        term: row.term,
        translation: row.translation,
        exampleSentence: row.exampleSentence,
        imageUrl: row.imageUrl,
        createdAt: row.createdAt,
      );
}
