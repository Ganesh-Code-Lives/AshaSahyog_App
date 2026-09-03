import '../assistant/models/chat_message.dart';

class AshaAssistantService {
  /// Returns a simulated response based on the user's message.
  /// Designed to be replaced with a real Gemini API backend later.
  Future<ChatMessage> getResponse(String userMessage) async {
    final lower = userMessage.toLowerCase();
    
    // Simulate network delay for realistic typing feel
    await Future.delayed(const Duration(milliseconds: 1200));

    if (lower.contains('hospital') || lower.contains('doctor') || lower.contains('clinic')) {
      return ChatMessage(
        text: "Sure! I can help you find healthcare services nearby. Let me take you to the hospital locator.",
        isUser: false,
        actionLabel: "Open Hospital Locator",
        actionRoute: "hospitals",
      );
    } 
    
    if (lower.contains('scheme') || lower.contains('government') || lower.contains('benefit') || lower.contains('eligible')) {
      return ChatMessage(
        text: "I can help you discover government schemes that may match your profile.",
        isUser: false,
        actionLabel: "Find My Schemes",
        actionRoute: "schemes",
      );
    }

    if (lower.contains('remind')) {
      return ChatMessage(
        text: "I can help you stay on top of important tasks and appointments.",
        isUser: false,
        actionLabel: "Create Reminder",
        actionRoute: "reminders",
      );
    }

    if (lower.contains('emergency') || lower.contains('help') || lower.contains('danger') || lower.contains('sos')) {
      return ChatMessage(
        text: "If this is an emergency, please seek immediate help. You can activate the emergency assistance feature from here.",
        isUser: false,
        actionLabel: "Open Emergency SOS",
        actionRoute: "sos",
      );
    }

    // Default fallback
    return ChatMessage(
      text: "I'm still learning, but I can help you explore AshaSahyog's healthcare services, government schemes, reminders, and emergency support.",
      isUser: false,
    );
  }
}
