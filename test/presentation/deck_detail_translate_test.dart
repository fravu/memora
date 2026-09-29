import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart' show AppDatabase;
import 'package:memora/domain/entities/deck.dart';
import 'package:memora/infrastructure/translation/translation_service.dart';
import 'package:memora/presentation/decks/deck_detail_screen.dart';
import 'package:memora/presentation/providers.dart';

class _FakeTranslationService implements TranslationService {
  @override
  Future<String?> translate(
    String text, {
    required String sourceLang,
    required String targetLang,
  }) async {
    return '$text-translated';
  }
}

void main() {
  testWidgets('Uebersetzen-Button fuellt das Uebersetzungsfeld', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final deck = Deck(
      id: 1,
      name: 'Deck',
      sourceLang: 'de',
      targetLang: 'en',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          translationServiceProvider.overrideWith((ref) => _FakeTranslationService()),
        ],
        child: MaterialApp(home: DeckDetailScreen(deck: deck)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Haus');
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    final translationField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(translationField.controller!.text, 'Haus-translated');

    await db.close();
  });
}
