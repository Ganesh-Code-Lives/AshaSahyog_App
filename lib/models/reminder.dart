import 'package:flutter/material.dart';

enum ReminderType { appointment, medication, custom }
enum RepeatType { none, daily, weekly }

class Reminder {
  final String id;
  final String title;
  final String description;
  final ReminderType type;
  final DateTime date;
  final TimeOfDay time;
  final RepeatType repeatType;
  final String colorTag;
  final DateTime createdAt;
  bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.time,
    required this.repeatType,
    required this.colorTag,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'repeatType': repeatType.toString(),
      'colorTag': colorTag,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final timeParts = json['time'].split(':');
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReminderType.custom,
      ),
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      repeatType: RepeatType.values.firstWhere(
        (e) => e.toString() == json['repeatType'],
        orElse: () => RepeatType.none,
      ),
      colorTag: json['colorTag'] ?? 'custom',
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
