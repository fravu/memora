import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/main.dart';
import 'package:memora/presentation/providers.dart';

void main() {
  testWidgets('Deck-Liste zeigt Leerzustand ohne Decks', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MemoraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Noch keine Decks. Leg eins an!'), findsOneWidget);

    // Drift schedules an internal Timer when a stream's last listener goes
    // away; awaiting close() here lets it finish before the widget tree is
    // torn down, otherwise flutter_test's pending-timer check fails.
    await db.close();
  });
}
