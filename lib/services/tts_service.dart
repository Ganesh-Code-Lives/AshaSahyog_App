import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused }

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  String? _lastSpokenText;
  int _playbackVersion = 0;
  bool _readingDocument = false;
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
    await setVoiceFeedbackEnabled(!isVoiceFeedbackEnabled, langCode: langCode);
  }

  /// Explicitly sets global voice feedback mode on or off.
  Future<void> setVoiceFeedbackEnabled(bool enabled, {String langCode = 'en'}) async {
    isVoiceFeedbackEnabled = enabled;
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
    bool force = false,
  }) async {
    if (!isVoiceFeedbackEnabled && !force) return;

    String msg = enMessage;
    if (langCode == 'hi' && hiMessage != null) msg = hiMessage;
    if (langCode == 'mr' && mrMessage != null) msg = mrMessage;

    await _speakInternal(msg, langCode: langCode);
  }

  /// Speaks main screen content or long text descriptions.
  Future<void> speak(
    String text, {
    String langCode = 'en',
    bool force = false,
  }) async {
    if (!isVoiceFeedbackEnabled && !force) return;
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
    final locale = _localeFor(langCode);

    try {
      await stop();
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

  String _localeFor(String langCode) => switch (langCode) {
    'hi' => 'hi-IN',
    'mr' => 'mr-IN',
    _ => 'en-IN',
  };

  /// Returns false when a suitable voice is unavailable or playback fails.
  Future<bool> readDocument(
    String text, {
    required String langCode,
    required double rate,
  }) async {
    final version = _playbackVersion + 1;
    await stop();
    if (version != _playbackVersion) return true;
    _readingDocument = true;
    try {
      final preferredLocale = _localeFor(langCode);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final voices = await _flutterTts.getVoices;
        if (version != _playbackVersion) return true;
        if (voices is! List) return false;
        Map<Object?, Object?>? selected;
        for (final voice in voices.whereType<Map<Object?, Object?>>()) {
          final locale = voice['locale'];
          final features = voice['features'] as String? ?? '';
          if (voice['network_required'] != '0' ||
              features.split('\t').contains('notInstalled') ||
              locale is! String ||
              locale.split('-').first != langCode ||
              voice['name'] is! String) {
            continue;
          }
          selected ??= voice;
          if (locale == preferredLocale) {
            selected = voice;
            break;
          }
        }
        if (selected == null) return false;
        if (await _flutterTts.setVoice({
              'name': selected['name'] as String,
              'locale': selected['locale'] as String,
            }) ==
            0) {
          return false;
        }
      } else {
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
        var locale = preferredLocale;
        var available = await _flutterTts.isLanguageAvailable(locale);
        if (available != true && available != 1 && langCode == 'en') {
          locale = 'en-US';
          available = await _flutterTts.isLanguageAvailable(locale);
        }
        if (version != _playbackVersion) return true;
        if (available != true && available != 1) return false;
        if (await _flutterTts.setLanguage(locale) == 0) return false;
      }
      if (version != _playbackVersion) return true;
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      if (version != _playbackVersion) return true;
      await _flutterTts.awaitSpeakCompletion(true);

      for (final chunk in _documentSpeechChunks(text)) {
        if (version != _playbackVersion) return true;
        final result = await _flutterTts.speak(chunk);
        if (result == 0 && version == _playbackVersion) return false;
      }
      return true;
    } on PlatformException {
      return version != _playbackVersion;
    } on MissingPluginException {
      return false;
    } finally {
      if (version == _playbackVersion) await stop();
    }
  }

  Iterable<String> _documentSpeechChunks(String text) sync* {
    const limit = 700;
    var start = 0;
    while (start < text.length) {
      var end = start + limit;
      if (end >= text.length) {
        end = text.length;
      } else {
        final boundary = text.lastIndexOf(RegExp(r'\s'), end);
        if (boundary > start) end = boundary + 1;
        // Keep a UTF-16 surrogate pair intact even in text without spaces.
        if (text.codeUnitAt(end - 1) >= 0xD800 &&
            text.codeUnitAt(end - 1) <= 0xDBFF) {
          end--;
        }
      }
      final chunk = text.substring(start, end).trim();
      if (chunk.isNotEmpty) yield chunk;
      start = end;
    }
  }

  Future<void> stop() async {
    _playbackVersion++;
    final readingDocument = _readingDocument;
    _readingDocument = false;
    try {
      await _flutterTts.stop();
      if (readingDocument) await _flutterTts.awaitSpeakCompletion(false);
    } catch (_) {}
    _ttsState = TtsState.stopped;
    stateNotifier.value = TtsState.stopped;
  }
}
