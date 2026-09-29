import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart' show AppDatabase;
import 'package:memora/main.dart';
import 'package:memora/presentation/providers.dart';

import '../fakes/fake_settings_repository.dart';

void main() {
  testWidgets('fuehrt durch die Onboarding-Seiten und landet auf der Deck-Liste',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fakeSettings = FakeSettingsRepository(onboardingComplete: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          settingsRepositoryProvider.overrideWith((ref) => fakeSettings),
        ],
        child: const MemoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Memora'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Klug wiederholen statt raten'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Los geht\'s'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Los geht\'s'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Decks. Leg eins an!'), findsOneWidget);
    expect(await fakeSettings.hasCompletedOnboarding(), isTrue);

    await db.close();
  });
}
