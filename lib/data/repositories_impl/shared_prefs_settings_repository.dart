import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

const _hourKey = 'reminder_hour';
const _minuteKey = 'reminder_minute';
const _onboardingCompleteKey = 'onboarding_complete';

class SharedPrefsSettingsRepository implements SettingsRepository {
  @override
  Future<(int hour, int minute)?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey);
    final minute = prefs.getInt(_minuteKey);
    if (hour == null || minute == null) return null;
    return (hour, minute);
  }

  @override
  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }

  @override
  Future<void> clearReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hourKey);
    await prefs.remove(_minuteKey);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  @override
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }
}
