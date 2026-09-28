import 'package:drift/drift.dart';

import '../../domain/entities/deck.dart' as domain;
import '../../domain/repositories/deck_repository.dart';
import '../drift/database.dart';

class DriftDeckRepository implements DeckRepository {
  DriftDeckRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain.Deck>> watchDecks() {
    return _db.select(_db.decks).watch().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  @override
  Future<int> createDeck({
    required String name,
    required String sourceLang,
    required String targetLang,
  }) {
    return _db.into(_db.decks).insert(
          DecksCompanion.insert(
            name: name,
            sourceLang: sourceLang,
            targetLang: targetLang,
          ),
        );
  }

  @override
  Future<void> renameDeck(int id, String newName) {
    return (_db.update(_db.decks)..where((d) => d.id.equals(id)))
        .write(DecksCompanion(name: Value(newName)));
  }

  @override
  Future<void> deleteDeck(int id) {
    return (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();
  }

  domain.Deck _toEntity(Deck row) => domain.Deck(
        id: row.id,
        name: row.name,
        sourceLang: row.sourceLang,
        targetLang: row.targetLang,
        createdAt: row.createdAt,
      );
}
