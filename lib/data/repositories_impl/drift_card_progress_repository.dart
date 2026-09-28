import 'package:drift/drift.dart';

import '../../domain/entities/card_progress.dart' as domain;
import '../../domain/entities/vocab.dart' as domain_vocab;
import '../../domain/repositories/card_progress_repository.dart';
import '../drift/database.dart';

class DriftCardProgressRepository implements CardProgressRepository {
  DriftCardProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain_vocab.Vocab>> watchDueVocabs(
    int deckId, {
    required DateTime asOf,
  }) {
    final query = _db.select(_db.vocabs).join([
      innerJoin(
        _db.cardProgresses,
        _db.cardProgresses.vocabId.equalsExp(_db.vocabs.id),
      ),
    ])
      ..where(
        _db.vocabs.deckId.equals(deckId) &
            _db.cardProgresses.dueDate.isSmallerOrEqualValue(asOf),
      )
      ..orderBy([OrderingTerm.asc(_db.cardProgresses.dueDate)]);

    return query.watch().map(
          (rows) =>
              rows.map((row) => _toVocabEntity(row.readTable(_db.vocabs))).toList(),
        );
  }

  @override
  Future<domain.CardProgress> getProgress(int vocabId) async {
    final row = await (_db.select(_db.cardProgresses)
          ..where((c) => c.vocabId.equals(vocabId)))
        .getSingle();
    return _toProgressEntity(row);
  }

  @override
  Future<void> saveProgress(domain.CardProgress progress) {
    return (_db.update(_db.cardProgresses)
          ..where((c) => c.vocabId.equals(progress.vocabId)))
        .write(
      CardProgressesCompanion(
        easeFactor: Value(progress.easeFactor),
        intervalDays: Value(progress.intervalDays),
        repetitions: Value(progress.repetitions),
        dueDate: Value(progress.dueDate),
        lastReviewedAt: Value(progress.lastReviewedAt),
      ),
    );
  }

  domain_vocab.Vocab _toVocabEntity(Vocab row) => domain_vocab.Vocab(
        id: row.id,
        deckId: row.deckId,
        term: row.term,
        translation: row.translation,
        exampleSentence: row.exampleSentence,
        imageUrl: row.imageUrl,
        createdAt: row.createdAt,
      );

  domain.CardProgress _toProgressEntity(CardProgressesData row) =>
      domain.CardProgress(
        id: row.id,
        vocabId: row.vocabId,
        easeFactor: row.easeFactor,
        intervalDays: row.intervalDays,
        repetitions: row.repetitions,
        dueDate: row.dueDate,
        lastReviewedAt: row.lastReviewedAt,
      );
}
