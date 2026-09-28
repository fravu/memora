import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

const _reminderNotificationId = 1;

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Kein Plugin fuer die native Zeitzone eingebunden (kein Overengineering
    // fuer die MVP-Erinnerung): wir leiten die Zone aus dem aktuellen
    // UTC-Offset ab. Achtung, Etc/GMT-Zonen kennen keine Sommerzeit, das
    // Vorzeichen ist zudem gegenueber der Alltagsschreibweise invertiert.
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final sign = offsetHours.isNegative ? '+' : '-';
    tz.setLocalLocation(tz.getLocation('Etc/GMT$sign${offsetHours.abs()}'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _reminderNotificationId,
      title: 'Zeit zum Lernen',
      body: 'Deine Vokabeln warten auf dich.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Tägliche Erinnerung',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderNotificationId);
  }
}
