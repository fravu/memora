import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/presentation/decks/deck_list_screen.dart';
import 'package:memora/presentation/providers.dart';

void main() {
  testWidgets('erstellt ein Deck über den Anlegen-Dialog', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: DeckListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Englisch Basics');
    await tester.tap(find.text('Anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Englisch Basics'), findsOneWidget);

    // See widget_test.dart for why this must be awaited before teardown.
    await db.close();
  });
}
