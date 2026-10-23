import 'package:flutter_test/flutter_test.dart';
import 'package:asha_sahyog/services/asha_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AshaAssistantService - Local Knowledge Engine & Fallback', () {
    final service = AshaAssistantService();

    test('responds accurately with hospital action for medical queries', () async {
      final response = await service.getResponse('Find doctors or hospitals near me');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'hospitals');
      expect(response.actionLabel, contains('Hospital'));
      expect(response.text.toLowerCase(), contains('hospital'));
    });

    test('responds accurately with schemes action for government benefit queries', () async {
      final response = await service.getResponse('Tell me about government schemes for disabled');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'schemes');
      expect(response.actionLabel, isNotNull);
      expect(response.text.toLowerCase(), contains('scheme'));
    });

    test('responds accurately with emergency SOS action for danger or crisis queries', () async {
      final response = await service.getResponse('I need emergency help right now');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'sos');
      expect(response.actionLabel, contains('Emergency'));
      expect(response.text, contains('112'));
    });

    test('responds accurately for UDID and certificate queries with documents route', () async {
      final response = await service.getResponse('How do I apply for a UDID disability card?');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'documents');
      expect(response.text, contains('UDID'));
    });

    test('responds accurately for medication or reminder queries', () async {
      final response = await service.getResponse('Remind me to take my medicine at 8pm');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'reminders');
      expect(response.actionLabel, contains('Reminder'));
    });

    test('responds accurately for Hindi hospital and scheme queries', () async {
      final response = await service.getResponse('मुझे नजदीकी अस्पताल ढूंढना है');
      expect(response.isUser, isFalse);
      expect(response.actionRoute, 'hospitals');
    });

    test('supports setting and clearing custom Gemini API key', () async {
      expect(await service.isAiConfigured(), isFalse);

      await service.setCustomApiKey('test_gemini_key_123');
      expect(await service.isAiConfigured(), isTrue);
      expect(await service.getActiveApiKey(), 'test_gemini_key_123');

      await service.clearCustomApiKey();
      expect(await service.isAiConfigured(), isFalse);
    });
  });
}
