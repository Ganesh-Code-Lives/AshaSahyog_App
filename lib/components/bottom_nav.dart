import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final Function(String) onNavigate;

  const BottomNav({super.key, required this.active, required this.onNavigate});

  void _handleTap(BuildContext context, String key, String label) {
    final langCode = context.read<LanguageProvider>().langCode;

    String enMsg = 'Opening $label';
    String hiMsg = '$label खोला जा रहा है';
    String mrMsg = '$label उघडत आहे';

    if (key == 'home') {
      enMsg = 'Opening Home';
      hiMsg = 'होम स्क्रीन खोली जा रही है';
      mrMsg = 'मुख्यपृष्ठ उघडत आहे';
    } else if (key == 'schemes') {
      enMsg = 'Opening Schemes Finder';
      hiMsg = 'योजनाएं खोली जा रही हैं';
      mrMsg = 'योजना शोध उघडत आहे';
    } else if (key == 'sos') {
      enMsg = 'Opening Emergency SOS';
      hiMsg = 'आपातकालीन सेवा खोली जा रही है';
      mrMsg = 'तातडीची मदत उघडत आहे';
    } else if (key == 'support') {
      enMsg = 'Opening Support and Helplines';
      hiMsg = 'सहायता और हेल्पलाइन खोली जा रही है';
      mrMsg = 'मदत आणि हेल्पलाइन उघडत आहे';
    } else if (key == 'profile') {
      enMsg = 'Opening User Profile';
      hiMsg = 'प्रोफ़ाइल खोली जा रही है';
      mrMsg = 'प्रोफाईल उघडत आहे';
    }

    TTSService().speakFeedback(enMsg, hiMessage: hiMsg, mrMessage: mrMsg, langCode: langCode);
    onNavigate(key);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 'home', Icons.home, 'Home'),
          _buildNavItem(context, 'schemes', Icons.description, 'Schemes'),
          
          // SOS Button
          InkWell(
            onTap: () => _handleTap(context, 'sos', 'Emergency SOS'),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: active == 'sos' ? AppTheme.primaryDark : AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active == 'sos' ? AppTheme.primaryDark : AppTheme.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: const Center(
                child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          _buildNavItem(context, 'support', Icons.headset_mic, 'Support'),
          _buildNavItem(context, 'profile', Icons.group, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String key, IconData icon, String label) {
    final isActive = active == key;
    final color = isActive ? AppTheme.primary : AppTheme.textSecondary;
    
    return InkWell(
      onTap: () => _handleTap(context, key, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
