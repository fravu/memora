import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/drift/database.dart';
import 'package:memora/data/repositories_impl/drift_stats_repository.dart';
import 'package:memora/presentation/providers.dart';
import 'package:memora/presentation/stats/stats_screen.dart';

void main() {
  testWidgets('zeigt Streak und Erfolgsquote nach Reviews an', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final statsRepo = DriftStatsRepository(db);
    await statsRepo.recordReview(wasCorrect: true);
    await statsRepo.recordReview(wasCorrect: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Tage Streak'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('Letzte 7 Tage'), findsOneWidget);

    await db.close();
  });

  testWidgets('zeigt einen leeren Zustand ohne Reviews', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 Tage Streak'), findsOneWidget);
    expect(find.text('Noch keine Lern-Session absolviert.'), findsOneWidget);

    await db.close();
  });
}
