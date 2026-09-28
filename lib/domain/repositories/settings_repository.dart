abstract class SettingsRepository {
  /// null, wenn keine Erinnerung eingestellt ist.
  Future<(int hour, int minute)?> getReminderTime();

  Future<void> setReminderTime(int hour, int minute);

  Future<void> clearReminderTime();
}
