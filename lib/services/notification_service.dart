import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:hive_flutter/hive_flutter.dart';
import '../core/logging/app_logger.dart';

class ReminderEntry {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final bool isActive;

  ReminderEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'scheduled_date': scheduledDate.toIso8601String(),
    'is_active': isActive,
  };

  factory ReminderEntry.fromJson(Map<String, dynamic> json) => ReminderEntry(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    scheduledDate: DateTime.parse(json['scheduled_date']),
    isActive: json['is_active'] ?? true,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notifications.initialize(initSettings);
      AppLogger.info('NotificationService initialized');
    } catch (e) {
      AppLogger.error('NotificationService initialization failed', error: e);
    }
  }

  Future<void> scheduleTreatmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) return;

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'guaverroots_treatment_reminders',
            'Treatment Reminders',
            channelDescription: 'Reminders for crop treatment applications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      await _saveReminder(ReminderEntry(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      ));

      AppLogger.info('Scheduled reminder: $title at $scheduledDate');
    } catch (e) {
      AppLogger.error('Failed to schedule reminder', error: e);
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _notifications.cancel(id);
      await _updateReminderStatus(id, false);
    } catch (e) {
      AppLogger.error('Failed to cancel reminder', error: e);
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      final box = Hive.box('reminder_box');
      await box.clear();
    } catch (e) {
      AppLogger.error('Failed to cancel all reminders', error: e);
    }
  }

  Future<List<ReminderEntry>> getScheduledReminders() async {
    final box = Hive.box('reminder_box');
    final entries = <ReminderEntry>[];
    for (final value in box.values) {
      if (value is Map) {
        entries.add(ReminderEntry.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    entries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return entries;
  }

  static Future<void> _saveReminder(ReminderEntry entry) async {
    final box = Hive.box('reminder_box');
    await box.put(entry.id, entry.toJson());
  }

  static Future<void> _updateReminderStatus(int id, bool isActive) async {
    final box = Hive.box('reminder_box');
    final raw = box.get(id);
    if (raw is Map) {
      final updated = Map<String, dynamic>.from(raw);
      updated['is_active'] = isActive;
      await box.put(id, updated);
    }
  }
}
