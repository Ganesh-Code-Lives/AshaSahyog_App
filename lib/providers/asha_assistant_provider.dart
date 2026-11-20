import 'package:flutter/material.dart';
import '../assistant/models/chat_message.dart';
import '../services/asha_assistant_service.dart';
import '../services/tts_service.dart';

class AshaAssistantProvider extends ChangeNotifier {
  final AshaAssistantService _service = AshaAssistantService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasGreeted = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get hasGreeted => _hasGreeted;

  void setHasGreeted(bool value) {
    _hasGreeted = value;
    notifyListeners();
  }

  void addUserMessage(String text) {
    if (text.trim().isEmpty) return;
    
    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();
    
    _fetchResponse(text);
  }

  void addAssistantMessage(ChatMessage message, {bool speak = true}) {
    _messages.add(message);
    notifyListeners();
    if (speak) {
      TTSService().speak(message.text);
    }
  }

  void clearChat() {
    _messages.clear();
    _hasGreeted = false;
    _isTyping = false;
    notifyListeners();
  }

  Future<bool> isCloudEnabled() => _service.isCloudEnabled();

  Future<void> setCloudEnabled(bool enabled) =>
      _service.setCloudEnabled(enabled);

  Future<void> _fetchResponse(String userText) async {
    try {
      final response = await _service.getResponse(
        userText,
        conversationHistory: _messages.sublist(0, _messages.length - 1),
      );
      _isTyping = false;
      addAssistantMessage(response);
    } catch (e) {
      _isTyping = false;
      addAssistantMessage(ChatMessage(
        text: "I'm having trouble connecting right now. Please try again later.",
        isUser: false,
      ));
    }
  }
}
