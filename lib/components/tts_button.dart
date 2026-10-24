import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// App-wide Speech/Accessibility Toggle Button for visually impaired and voice-assisted users.
class TtsButton extends StatelessWidget {
  final String? textToRead;
  final String? tooltip;
  final bool compact;
  final bool translucent;
  final Color? activeColor;
  final Color? inactiveColor;

  const TtsButton({
    super.key,
    this.textToRead,
    this.tooltip,
    this.compact = false,
    this.translucent = false,
    this.activeColor,
    this.inactiveColor,
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
        final label = isVoiceOn
            ? AppStrings.t(context, 'voice_on', 'Voice ON')
            : AppStrings.t(context, 'voice_off', 'Voice OFF');
        final currentTooltip = tooltip ?? (isVoiceOn ? 'Mute Voice Output' : 'Enable Voice Output');

        if (compact) {
          return Tooltip(
            message: currentTooltip,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  TTSService().toggleVoiceFeedback(langCode: langCode);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: translucent
                        ? (isVoiceOn ? Colors.white.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.2))
                        : (isVoiceOn ? (activeColor ?? AppTheme.primary) : (inactiveColor ?? Colors.grey.shade400)),
                    shape: BoxShape.circle,
                    border: translucent
                        ? Border.all(
                            color: isVoiceOn ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: isVoiceOn && !translucent
                        ? [
                            BoxShadow(
                              color: (activeColor ?? AppTheme.primary).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isVoiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          );
        }

        return Tooltip(
          message: currentTooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                TTSService().toggleVoiceFeedback(langCode: langCode);
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: translucent
                      ? (isVoiceOn ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.2))
                      : (isVoiceOn ? (activeColor ?? AppTheme.primary) : (inactiveColor ?? Colors.grey.shade600)),
                  borderRadius: BorderRadius.circular(24),
                  border: translucent
                      ? Border.all(
                          color: isVoiceOn ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.25),
                          width: 1.2,
                        )
                      : null,
                  boxShadow: isVoiceOn && !translucent
                      ? [
                          BoxShadow(
                            color: (activeColor ?? AppTheme.primary).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVoiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
