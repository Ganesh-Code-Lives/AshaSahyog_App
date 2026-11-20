import 'dart:async';

import 'package:asha_sahyog/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const offlineMarathi = {
    'name': 'marathi-offline',
    'locale': 'mr-IN',
    'network_required': '0',
    'features': '',
  };
  const onlineMarathi = {
    'name': 'marathi-online',
    'locale': 'mr-IN',
    'network_required': '1',
  };

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('uses an offline Marathi voice and chunks a long document', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getVoices') return [onlineMarathi, offlineMarathi];
      return 1;
    });
    final source = List.filled(200, 'मराठी मजकूर').join(' ');

    expect(
      await TTSService().readDocument(source, langCode: 'mr', rate: 0.4),
      isTrue,
    );
    expect(calls.singleWhere((call) => call.method == 'setVoice').arguments, {
      'name': 'marathi-offline',
      'locale': 'mr-IN',
    });
    expect(
      calls.singleWhere((call) => call.method == 'setSpeechRate').arguments,
      0.4,
    );
    final chunks = calls
        .where((call) => call.method == 'speak')
        .map((call) => call.arguments as String)
        .toList();
    expect(chunks.length, greaterThan(1));
    expect(chunks.join(' '), source);
  });

  test('declines playback when only a network voice is available', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'getVoices' ? [onlineMarathi] : 1;
    });
    expect(
      await TTSService().readDocument('मजकूर', langCode: 'mr', rate: 0.5),
      isFalse,
    );
    expect(calls, isNot(contains('speak')));
  });

  test('Stop prevents remaining document chunks from playing', () async {
    final firstUtterance = Completer<void>();
    final speechResult = Completer<int>();
    var speakCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVoices') return [offlineMarathi];
      if (call.method == 'speak') {
        speakCalls++;
        firstUtterance.complete();
        return speechResult.future;
      }
      if (call.method == 'stop' &&
          firstUtterance.isCompleted &&
          !speechResult.isCompleted) {
        speechResult.complete(0);
      }
      return 1;
    });
    final service = TTSService();
    final playback = service.readDocument(
      List.filled(200, 'मराठी मजकूर').join(' '),
      langCode: 'mr',
      rate: 0.5,
    );
    await firstUtterance.future;
    await service.stop();
    expect(await playback, isTrue);
    expect(speakCalls, 1);
  });
}
