import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  // Optional action parameters (e.g. "Open Hospital Locator")
  final String? actionLabel;
  final String? actionRoute;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.actionLabel,
    this.actionRoute,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}
