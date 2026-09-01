import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// App-wide Speech/Accessibility Toggle Button for visually impaired users.
class TtsButton extends StatelessWidget {
  final String? textToRead;
  final String? tooltip;

  const TtsButton({
    super.key,
    this.textToRead,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    String langCode = 'en';
    try {
      langCode = context.watch<LanguageProvider>().langCode;
    } catch (_) {}

    return ValueListenableBuilder<bool>(
      valueListenable: TTSService().voiceFeedbackNotifier,
      builder: (context, isVoiceOn, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              TTSService().toggleVoiceFeedback(langCode: langCode);
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isVoiceOn ? AppTheme.primary : Colors.grey.shade600,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isVoiceOn
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVoiceOn ? Icons.record_voice_over : Icons.voice_over_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isVoiceOn
                        ? (langCode == 'hi' ? 'वॉयस ऑन' : langCode == 'mr' ? 'व्हॉइस ऑन' : 'Voice ON')
                        : (langCode == 'hi' ? 'वॉयस ऑफ' : langCode == 'mr' ? 'व्हॉइस ऑफ' : 'Voice OFF'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
