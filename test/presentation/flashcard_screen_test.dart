import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart' show AppDatabase;
import 'package:memora/data/repositories_impl/drift_deck_repository.dart';
import 'package:memora/data/repositories_impl/drift_vocab_repository.dart';
import 'package:memora/domain/entities/deck.dart';
import 'package:memora/infrastructure/tts/tts_service.dart';
import 'package:memora/presentation/providers.dart';
import 'package:memora/presentation/review/flashcard_screen.dart';

class _FakeTtsService implements TtsService {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    spoken.add('$languageCode:$text');
  }
}

void main() {
  testWidgets('zeigt die faelligste Karte, spielt Audio ab und bewertet sie',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final deckId = await DriftDeckRepository(db).createDeck(
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
    );
    await DriftVocabRepository(db).addVocab(
      deckId: deckId,
      term: 'Haus',
      translation: 'house',
    );
    final deck = Deck(
      id: deckId,
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
      createdAt: DateTime.now(),
    );
    final fakeTts = _FakeTtsService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          ttsServiceProvider.overrideWith((ref) => fakeTts),
        ],
        child: MaterialApp(home: FlashcardScreen(deck: deck)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Haus'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(fakeTts.spoken, ['de:Haus']);

    await tester.tap(find.text('Umdrehen'));
    await tester.pumpAndSettle();
    expect(find.text('house'), findsOneWidget);

    await tester.tap(find.text('Gut'));
    await tester.pumpAndSettle();

    expect(find.text('Keine fälligen Karten. Gut gemacht!'), findsOneWidget);

    await db.close();
  });
}
