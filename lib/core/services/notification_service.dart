import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/medication.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();
    // MVP: assume Nepal by default (works offline, no extra plugin).
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> scheduleMedicationReminders({required Medication med}) async {
    await init();
    final times = (med.schedule['times'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < times.length; i++) {
      final timeStr = times[i];
      final hhmm = _parseHHmm(timeStr);
      if (hhmm == null) continue;

      final id = _notifId(med.id, i);
      final next = _nextInstanceOfTime(hhmm.$1, hhmm.$2);

      await _plugin.zonedSchedule(
        id,
        'Medication reminder',
        '${med.name} • ${med.dosage}',
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication reminders',
            channelDescription: 'Daily medication reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'assistant',
      );
    }
  }

  int _notifId(String medId, int index) {
    // Stable-ish int ID derived from medId.
    return medId.hashCode ^ (index + 1) * 9973;
  }

  (int, int)? _parseHHmm(String s) {
    final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(s.trim());
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
