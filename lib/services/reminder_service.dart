import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  static const String _remindersKey = 'saved_reminders';

  // Load all reminders
  static Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString(_remindersKey);
    
    if (remindersJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(remindersJson);
      return decoded.map((item) => Reminder.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      return [];
    }
  }

  // Save all reminders
  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, encoded);
  }

  // Generate a stable integer ID for notifications
  static int _getNotificationId(String uuid) {
    final cleanUuid = uuid.replaceAll('-', '');
    if (cleanUuid.length < 7) {
      return cleanUuid.hashCode;
    }
    // Use the first 7 characters of the UUID to create a stable integer (max 0xFFFFFFF)
    return int.parse(cleanUuid.substring(0, 7), radix: 16);
  }

  // Schedule a notification
  static void _scheduleNotificationForReminder(Reminder reminder) {
    if (reminder.isCompleted) return;

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      if (reminder.repeatType == RepeatType.daily) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      } else if (reminder.repeatType == RepeatType.weekly) {
        scheduledTime = scheduledTime.add(const Duration(days: 7));
      } else {
        return; 
      }
    }

    final id = _getNotificationId(reminder.id);
    final title = reminder.title;
    final body = reminder.description.isNotEmpty ? reminder.description : 'You have a reminder!';

    NotificationService().scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      repeatType: reminder.repeatType == RepeatType.daily 
          ? 'daily' 
          : (reminder.repeatType == RepeatType.weekly ? 'weekly' : null),
    );
  }

  // Add a reminder
  static Future<void> addReminder(Reminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
    _scheduleNotificationForReminder(reminder);
  }

  // Update a reminder
  static Future<void> updateReminder(Reminder updatedReminder) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await saveReminders(reminders);
      await NotificationService().cancelNotification(_getNotificationId(updatedReminder.id));
      _scheduleNotificationForReminder(updatedReminder);
    }
  }

  // Delete a reminder
  static Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
    await NotificationService().cancelNotification(_getNotificationId(id));
  }
}
