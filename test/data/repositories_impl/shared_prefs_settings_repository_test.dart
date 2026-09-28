import 'package:flutter_test/flutter_test.dart';
import 'package:memora/data/repositories_impl/shared_prefs_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getReminderTime returns null when nothing was set', () async {
    final repo = SharedPrefsSettingsRepository();
    expect(await repo.getReminderTime(), isNull);
  });

  test('setReminderTime persists hour and minute', () async {
    final repo = SharedPrefsSettingsRepository();
    await repo.setReminderTime(8, 30);

    expect(await repo.getReminderTime(), (8, 30));
  });

  test('clearReminderTime removes a previously set time', () async {
    final repo = SharedPrefsSettingsRepository();
    await repo.setReminderTime(8, 30);
    await repo.clearReminderTime();

    expect(await repo.getReminderTime(), isNull);
  });
}
