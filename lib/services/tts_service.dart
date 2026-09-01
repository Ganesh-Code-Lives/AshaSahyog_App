import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused }

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  String? _lastSpokenText;
  bool isVoiceFeedbackEnabled = true;

  TtsState get ttsState => _ttsState;
  bool get isPlaying => _ttsState == TtsState.playing;

  final ValueNotifier<TtsState> stateNotifier = ValueNotifier<TtsState>(
    TtsState.stopped,
  );

  final ValueNotifier<bool> voiceFeedbackNotifier = ValueNotifier<bool>(true);

  TTSService._internal() {
    _initTts();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isVoiceFeedbackEnabled = prefs.getBool('voice_feedback_enabled') ?? true;
    voiceFeedbackNotifier.value = isVoiceFeedbackEnabled;
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      stateNotifier.value = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      stateNotifier.value = TtsState.stopped;
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _ttsState = TtsState.stopped;
      stateNotifier.value = TtsState.stopped;
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      stateNotifier.value = TtsState.stopped;
    });
  }

  /// Toggles global voice feedback mode on or off.
  Future<void> toggleVoiceFeedback({String langCode = 'en'}) async {
    isVoiceFeedbackEnabled = !isVoiceFeedbackEnabled;
    voiceFeedbackNotifier.value = isVoiceFeedbackEnabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_feedback_enabled', isVoiceFeedbackEnabled);

    if (isVoiceFeedbackEnabled) {
      String msg = 'Voice Screen Reader Enabled';
      if (langCode == 'hi') msg = 'वॉयस स्क्रीन रीडर चालू किया गया';
      if (langCode == 'mr') msg = 'व्हॉइस स्क्रीन रीडर सुरू केले';
      await _speakInternal(msg, langCode: langCode);
    } else {
      await stop();
    }
  }

  /// Speaks interactive button/navigation feedback immediately if voice feedback is enabled.
  Future<void> speakFeedback(
    String enMessage, {
    String? hiMessage,
    String? mrMessage,
    String langCode = 'en',
  }) async {
    if (!isVoiceFeedbackEnabled) return;

    String msg = enMessage;
    if (langCode == 'hi' && hiMessage != null) msg = hiMessage;
    if (langCode == 'mr' && mrMessage != null) msg = mrMessage;

    await _speakInternal(msg, langCode: langCode);
  }

  /// Speaks main screen content or long text descriptions.
  Future<void> speak(String text, {String langCode = 'en'}) async {
    if (text.trim().isEmpty) return;

    if (isPlaying && _lastSpokenText == text) {
      await stop();
      return;
    }

    await stop();
    _lastSpokenText = text;

    await _speakInternal(text, langCode: langCode);
  }

  Future<void> _speakInternal(
    String text, {
    required String langCode,
  }) async {
    String locale = 'en-IN';
    if (langCode == 'hi') locale = 'hi-IN';
    if (langCode == 'mr') locale = 'mr-IN';

    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage(locale);
      await _flutterTts.setSpeechRate(0.65); // Uniform 0.65 speech rate throughout
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Speak exception: $e');
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.65);
        await _flutterTts.speak(text);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _ttsState = TtsState.stopped;
    stateNotifier.value = TtsState.stopped;
  }
}
