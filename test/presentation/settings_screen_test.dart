import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/repositories/settings_repository.dart';
import 'package:memora/infrastructure/notifications/notification_service.dart';
import 'package:memora/presentation/providers.dart';
import 'package:memora/presentation/settings/settings_screen.dart';

class _FakeSettingsRepository implements SettingsRepository {
  (int, int)? _time;

  @override
  Future<(int, int)?> getReminderTime() async => _time;

  @override
  Future<void> setReminderTime(int hour, int minute) async {
    _time = (hour, minute);
  }

  @override
  Future<void> clearReminderTime() async {
    _time = null;
  }
}

class _FakeNotificationService implements NotificationService {
  bool cancelled = false;
  (int, int)? scheduled;

  @override
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    scheduled = (hour, minute);
  }

  @override
  Future<void> cancelReminder() async {
    cancelled = true;
  }
}

void main() {
  testWidgets('zeigt "Nicht gesetzt" ohne gespeicherte Erinnerung', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => _FakeSettingsRepository()),
          notificationServiceProvider.overrideWith((ref) => _FakeNotificationService()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nicht gesetzt'), findsOneWidget);
  });

  testWidgets('zeigt eine zuvor gespeicherte Erinnerungszeit an', (tester) async {
    final fakeSettings = _FakeSettingsRepository();
    await fakeSettings.setReminderTime(7, 15);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => fakeSettings),
          notificationServiceProvider.overrideWith((ref) => _FakeNotificationService()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Um 07:15 Uhr'), findsOneWidget);
  });

  testWidgets('Erinnerung ausschalten ruft cancelReminder auf', (tester) async {
    final fakeSettings = _FakeSettingsRepository();
    await fakeSettings.setReminderTime(7, 15);
    final fakeNotifications = _FakeNotificationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => fakeSettings),
          notificationServiceProvider.overrideWith((ref) => fakeNotifications),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(fakeNotifications.cancelled, isTrue);
    expect(find.text('Nicht gesetzt'), findsOneWidget);
  });
}
