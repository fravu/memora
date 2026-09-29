import 'package:memora/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.onboardingComplete = true});

  (int, int)? _time;
  bool onboardingComplete;

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

  @override
  Future<bool> hasCompletedOnboarding() async => onboardingComplete;

  @override
  Future<void> setOnboardingComplete() async {
    onboardingComplete = true;
  }
}
