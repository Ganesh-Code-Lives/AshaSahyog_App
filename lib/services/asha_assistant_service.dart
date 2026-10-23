import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../assistant/models/chat_message.dart';

class AshaAssistantService {
  // Singleton pattern
  static final AshaAssistantService _instance = AshaAssistantService._internal();
  factory AshaAssistantService() => _instance;
  AshaAssistantService._internal();

  static const String _geminiEnvKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _prefKeyGemini = 'custom_gemini_api_key';
  static const String _defaultModel = 'gemini-1.5-flash';

  /// Returns the currently active Gemini API key (from SharedPreferences or --dart-define).
  Future<String> getActiveApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customKey = prefs.getString(_prefKeyGemini)?.trim() ?? '';
      if (customKey.isNotEmpty) return customKey;
    } catch (e) {
      debugPrint('Error reading SharedPreferences for Gemini key: $e');
    }
    return _geminiEnvKey.trim();
  }

  /// Allows the user or developer to set a custom Gemini API key at runtime.
  Future<void> setCustomApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyGemini, key.trim());
  }

  /// Clears any runtime-saved Gemini API key.
  Future<void> clearCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyGemini);
  }

  /// Whether Gemini AI has an active API key configured.
  Future<bool> isAiConfigured() async {
    final key = await getActiveApiKey();
    return key.isNotEmpty;
  }

  /// Returns an intelligent assistant response, using Google Gemini AI if configured,
  /// with automatic fallback to the local knowledge engine on error or when offline.
  Future<ChatMessage> getResponse(
    String userMessage, {
    List<ChatMessage> conversationHistory = const [],
  }) async {
    final apiKey = await getActiveApiKey();

    if (apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _callGeminiApi(
          userMessage: userMessage,
          apiKey: apiKey,
          history: conversationHistory,
        );
        if (geminiResponse != null) {
          return geminiResponse;
        }
      } catch (e) {
        debugPrint('Gemini API call failed, falling back to local engine: $e');
      }
    }

    // Local Intelligent Knowledge Engine fallback
    return _generateLocalResponse(userMessage);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  GEMINI API CALL
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChatMessage?> _callGeminiApi({
    required String userMessage,
    required String apiKey,
    required List<ChatMessage> history,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$apiKey',
    );

    const systemPrompt = '''
You are Asha, the warm, empathetic, and expert AI assistant inside the AshaSahyog mobile application.
AshaSahyog is an accessible welfare & assistance platform designed for Divyangjan (Persons with Disabilities / PwD) in India and their caregivers.

Your core expertise:
1. Government welfare schemes in India: UDID (Unique Disability ID), ADIP Scheme (aids & appliances like wheelchairs, tricycles, hearing aids), Disability Pensions, National Handicapped Finance (NHFDC), scholarships for PwD, railway & bus travel concessions, and DDRS.
2. Healthcare: Finding nearby accessible hospitals, clinics, and doctors.
3. Organization & Care: Setting medication/checkup reminders and securely storing certificates in the Document Vault.
4. Safety: Emergency SOS assistance with GPS coordinates for urgent help.

Guidelines:
- Match the user's language (English, Hindi, or Marathi).
- Be polite, concise, encouraging, and clear. Avoid overly dense walls of text; use bullet points for lists.
- If the query directly relates to an in-app feature, suggest an action by appending this EXACT tag at the very end of your response on its own line:
  [[ACTION:route:Button Label]]

Valid routes and recommended labels:
- [[ACTION:hospitals:Open Hospital Locator]] (for hospitals, clinics, doctors, medical facilities)
- [[ACTION:schemes:Explore Schemes]] (for government welfare schemes, benefits, grants)
- [[ACTION:recommendations:Check Scheme Eligibility]] (for personalized scheme recommendations)
- [[ACTION:reminders:Set a Reminder]] (for medicine timings, doctor appointments, alarms)
- [[ACTION:documents:Open Document Vault]] (for UDID card, disability certificates, documents)
- [[ACTION:sos:Emergency SOS]] (for emergencies, distress, urgent medical help)
- [[ACTION:profile:View Profile]] (for updating disability category, percentage, or income)
- [[ACTION:support:Contact Support]] (for customer helpline or contact)

Never output more than ONE [[ACTION:...]] tag.
''';

    // Build multi-turn contents from recent history (last 6 messages max)
    final List<Map<String, dynamic>> contents = [];

    final recentHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    for (final msg in recentHistory) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      });
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final body = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 800,
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final rawText = parts[0]['text'] as String? ?? '';
          return _parseResponseWithAction(rawText, userMessage);
        }
      }
    } else {
      debugPrint('Gemini API Error: Status ${response.statusCode} - ${response.body}');
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  RESPONSE PARSER & ACTION EXTRACTOR
  // ──────────────────────────────────────────────────────────────────────────
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
