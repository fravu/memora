abstract class NotificationService {
  Future<void> scheduleDailyReminder({required int hour, required int minute});

  Future<void> cancelReminder();
}
