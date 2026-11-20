import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../assistant/models/chat_message.dart';

class AshaAssistantService {
  static final AshaAssistantService _instance = AshaAssistantService._internal();
  factory AshaAssistantService() => _instance;
  AshaAssistantService._internal();

  static const _cloudPreference = 'assistant_cloud_enabled';

  Future<void> removeLegacyApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('custom_gemini_api_key')) {
        await prefs.remove('custom_gemini_api_key');
      }
    } catch (_) {
      // Preferences may be unavailable on initial launch.
    }
  }

  Future<bool> isCloudEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudPreference) ?? false;
  }

  Future<void> setCloudEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudPreference, enabled);
  }

  Future<ChatMessage> getResponse(
    String userMessage, {
    List<ChatMessage> conversationHistory = const [],
  }) async {
    try {
      if (await isCloudEnabled()) {
        final client = Supabase.instance.client;
        if (client.auth.currentSession != null) {
          final recent = conversationHistory.reversed.take(6).toList().reversed;
          final response = await client.functions
              .invoke('asha-assistant', body: {
                'message': userMessage,
                'history': [
                  for (final turn in recent)
                    {'role': turn.isUser ? 'user' : 'model', 'text': turn.text},
                ],
              })
              .timeout(const Duration(seconds: 15));
          final body = response.data;
          final text = body is Map ? body['text'] : null;
          if (text is String && text.trim().isNotEmpty) {
            return _parseResponseWithAction(text, userMessage);
          }
        }
      }
    } catch (_) {
      // The built-in assistant remains available when cloud AI fails.
    }

    return _generateLocalResponse(userMessage);
  }

  ChatMessage _parseResponseWithAction(String rawText, String userMessage) {
    String cleanText = rawText.trim();
    String? actionRoute;
    String? actionLabel;

    // Check for [[ACTION:route:label]] tag
    final actionRegex = RegExp(r'\[\[ACTION:([a-zA-Z0-9_]+):([^\]]+)\]\]');
    final match = actionRegex.firstMatch(cleanText);

    if (match != null) {
      actionRoute = match.group(1)?.trim();
      actionLabel = match.group(2)?.trim();
      cleanText = cleanText.replaceAll(match.group(0)!, '').trim();
    } else {
      // In case Gemini forgot the tag, deduce route from text or user input
      final deduced = _deduceAction(userMessage, cleanText);
      if (deduced != null) {
        actionRoute = deduced.route;
        actionLabel = deduced.label;
      }
    }

    return ChatMessage(
      text: cleanText,
      isUser: false,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
    );
  }

  _ActionDeduction? _deduceAction(String userMsg, String responseText) {
    final text = '$userMsg $responseText'.toLowerCase();
    if (text.contains('hospital') || text.contains('doctor') || text.contains('clinic')) {
      return const _ActionDeduction('hospitals', 'Open Hospital Locator');
    }
    if (text.contains('scheme') || text.contains('adip') || text.contains('pension') || text.contains('subsidy')) {
      return const _ActionDeduction('schemes', 'Explore Schemes');
    }
    if (text.contains('remind') || text.contains('medicine') || text.contains('alarm')) {
      return const _ActionDeduction('reminders', 'Set a Reminder');
    }
    if (text.contains('udid') || text.contains('certificate') || text.contains('vault') || text.contains('document')) {
      return const _ActionDeduction('documents', 'Open Document Vault');
    }
    if (text.contains('emergency') || text.contains('sos') || text.contains('danger') || text.contains('crisis')) {
      return const _ActionDeduction('sos', 'Open Emergency SOS');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  LOCAL INTELLIGENT KNOWLEDGE ENGINE (OFFLINE FALLBACK)
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChatMessage> _generateLocalResponse(String userMessage) async {
    // Slight realistic typing delay for local processing
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = userMessage.toLowerCase().trim();

    // 1. Emergency & SOS
    if (lower.contains('emergency') ||
        lower.contains('sos') ||
        lower.contains('danger') ||
        lower.contains('help me') ||
        lower.contains('संकट') ||
        lower.contains('आपातकालीन') ||
        lower.contains('मदत')) {
      return ChatMessage(
        text: "🚨 **Emergency SOS Support**\n\n"
            "If you or someone around you is in immediate danger or requires urgent medical help, please use the Emergency SOS button.\n\n"
            "This will instantly trigger your emergency alerts and send your live GPS location to your trusted contacts.\n\n"
            "• National Emergency Number: **112**\n"
            "• Ambulance: **108**",
        isUser: false,
        actionLabel: "Open Emergency SOS",
        actionRoute: "sos",
      );
    }

    // 2. Hospitals & Healthcare
    if (lower.contains('hospital') ||
        lower.contains('doctor') ||
        lower.contains('clinic') ||
        lower.contains('healthcare') ||
        lower.contains('medical') ||
        lower.contains('अस्पताल') ||
        lower.contains('दवाखाना')) {
      return ChatMessage(
        text: "🏥 **Nearby Healthcare & Hospitals**\n\n"
            "AshaSahyog includes an interactive Hospital Locator that finds verified hospitals, health centers, and clinics near your current location using GPS.\n\n"
            "You can view distance, address, and launch direct turn-by-turn navigation.",
        isUser: false,
        actionLabel: "Open Hospital Locator",
        actionRoute: "hospitals",
      );
    }

    // 3. UDID Card & Disability Certificate
    if (lower.contains('udid') ||
        lower.contains('disability card') ||
        lower.contains('swavlamban') ||
        lower.contains('यूडीआईडी') ||
        lower.contains('प्रमाणपत्र')) {
      return ChatMessage(
        text: "🆔 **UDID (Unique Disability ID) Card**\n\n"
            "The UDID card is issued by the Ministry of Social Justice & Empowerment (DEPwD) to uniquely identify PwD across India.\n\n"
            "**Key benefits:**\n"
            "• Single document for verifying disability nationwide\n"
            "• Essential for availing travel concessions, pensions, and ADIP aids\n"
            "• Track status on: **swavlambancard.gov.in**\n\n"
            "You can save and secure your UDID card right inside our **Document Vault**.",
        isUser: false,
        actionLabel: "Open Document Vault",
        actionRoute: "documents",
      );
    }

    // 4. Document Vault
    if (lower.contains('document') ||
        lower.contains('vault') ||
        lower.contains('certificate') ||
        lower.contains('upload') ||
        lower.contains('aadhaar') ||
        lower.contains('दस्तावेज़') ||
        lower.contains('कागदपत्र')) {
      return ChatMessage(
        text: "📁 **Secure Document Vault**\n\n"
            "You can safely store and access all your essential disability documents on your device, including:\n\n"
            "• UDID Card & Medical Certificates\n"
            "• Disability Assessment Reports\n"
            "• Aadhaar & Income Certificates\n"
            "• Prescription and Medical Records\n\n"
            "Keep them ready whenever you apply for schemes or visit government centers.",
        isUser: false,
        actionLabel: "Open Document Vault",
        actionRoute: "documents",
      );
    }

    // 5. ADIP Scheme (Aids & Assistive Devices)
    if (lower.contains('adip') ||
        lower.contains('wheelchair') ||
        lower.contains('hearing aid') ||
        lower.contains('crutch') ||
        lower.contains('prosthetic') ||
        lower.contains('device') ||
        lower.contains('उपकरण')) {
      return ChatMessage(
        text: "♿ **ADIP Scheme (Assistance to Disabled Persons)**\n\n"
            "ADIP provides free or subsidized modern, high-quality assistive aids and appliances to persons with disabilities.\n\n"
            "**Eligibility:**\n"
            "• Minimum 40% disability (certified by a medical board)\n"
            "• Monthly family income up to ₹20,000 for 100% subsidy\n"
            "• Devices: Wheelchairs, motorized tricycles, hearing aids, braille kits, prosthetics, and smartphones for visually impaired.",
        isUser: false,
        actionLabel: "Explore ADIP Scheme",
        actionRoute: "schemes",
      );
    }

    // 6. Schemes & Pensions
    if (lower.contains('scheme') ||
        lower.contains('pension') ||
        lower.contains('scholarship') ||
        lower.contains('benefit') ||
        lower.contains('welfare') ||
        lower.contains('grant') ||
        lower.contains('योजना') ||
        lower.contains('पेंशन')) {
      return ChatMessage(
        text: "📜 **Government Welfare Schemes**\n\n"
            "AshaSahyog tracks key Central & State disability welfare programs:\n\n"
            "1. **ADIP Scheme** — Free aids and assistive appliances\n"
            "2. **Divyangjan Swavalamban Yojana** — Concessional loans for self-employment\n"
            "3. **National Disability Pension (IGNDPS)** — Monthly financial assistance\n"
            "4. **Pre/Post-Matric Scholarships** — Educational support for disabled students\n"
            "5. **Railway & Bus Concessions** — Subsidized travel across India",
        isUser: false,
        actionLabel: "Find My Schemes",
        actionRoute: "schemes",
      );
    }

    // 7. Reminders & Medication
    if (lower.contains('remind') ||
        lower.contains('medicine') ||
        lower.contains('pill') ||
        lower.contains('appointment') ||
        lower.contains('alarm') ||
        lower.contains('याद') ||
        lower.contains('दवा')) {
      return ChatMessage(
        text: "⏰ **Smart Reminders & Schedules**\n\n"
            "Never miss critical healthcare tasks! You can set personalized notifications for:\n\n"
            "• Daily medicine and therapy timings\n"
            "• Hospital and doctor visits\n"
            "• UDID / Certificate renewal dates\n"
            "• Scheme application deadlines",
        isUser: false,
        actionLabel: "Create Reminder",
        actionRoute: "reminders",
      );
    }

    // 8. Profile & Eligibility Check
    if (lower.contains('profile') ||
        lower.contains('percentage') ||
        lower.contains('eligib') ||
        lower.contains('recommend') ||
        lower.contains('my details')) {
      return ChatMessage(
        text: "🎯 **Smart Scheme Recommendations**\n\n"
            "Our automated Eligibility Engine matches your profile (age, disability type, percentage, income, and state) against official scheme criteria to tell you exactly which benefits you qualify for.",
        isUser: false,
        actionLabel: "Check My Eligibility",
        actionRoute: "recommendations",
      );
    }

    // 9. Support & Helpline
    if (lower.contains('support') ||
        lower.contains('contact') ||
        lower.contains('help') ||
        lower.contains('helpline') ||
        lower.contains('phone')) {
      return ChatMessage(
        text: "📞 **Divyangjan Help & Support**\n\n"
            "You can reach out to dedicated welfare support:\n\n"
            "• **National PwD Helpline:** 1800-180-5122 (Toll-Free)\n"
            "• **KIRAN Mental Health Helpline:** 1800-599-0019\n"
            "• **AshaSahyog Support Team:** support@ashasahyog.org\n\n"
            "You can also access the in-app Support screen anytime.",
        isUser: false,
        actionLabel: "Contact Support",
        actionRoute: "support",
      );
    }

    // 10. Greetings & Identity
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey') ||
        lower.contains('namaste') ||
        lower.contains('who are you') ||
        lower.contains('what can you do') ||
        lower.contains('नमस्ते')) {
      return ChatMessage(
        text: "Hello! 🙏 I am **Asha**, your personal AshaSahyog assistant.\n\n"
            "I'm here to help you navigate welfare programs and services for persons with disabilities in India:\n\n"
            "• 🏥 **Hospitals:** Find accessible healthcare near you\n"
            "• 📜 **Schemes:** Discover eligible government welfare benefits\n"
            "• 🆔 **UDID & Vault:** Guide you on disability cards & store documents\n"
            "• ⏰ **Reminders:** Schedule medicine & appointment alerts\n"
            "• 🚨 **SOS:** Quick emergency assistance with GPS\n\n"
            "What would you like assistance with today?",
        isUser: false,
        actionLabel: "Find My Schemes",
        actionRoute: "schemes",
      );
    }

    // Default intelligent fallback
    return ChatMessage(
      text: "I can help you explore AshaSahyog's services, including **Government Schemes** (ADIP, UDID, Pensions), **Nearby Hospitals**, **Document Vault**, **Medicine Reminders**, and **Emergency SOS**.\n\n"
          "You can ask me questions like:\n"
          "• *\"What benefits does the ADIP scheme offer?\"*\n"
          "• *\"How do I get a UDID card?\"*\n"
          "• *\"Find a hospital near me\"*\n"
          "• *\"Set a reminder for my medicine\"*",
      isUser: false,
      actionLabel: "Explore Government Schemes",
      actionRoute: "schemes",
    );
  }
}

class _ActionDeduction {
  final String route;
  final String label;
  const _ActionDeduction(this.route, this.label);
}
