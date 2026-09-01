import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'providers/language_provider.dart';

import 'components/tts_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();
  
  // ── Supabase credentials ──────────────────────────────────────────
  // Values are injected at build/run time via:
  //   flutter run --dart-define-from-file=.env
  // Never hardcode secrets here. See .env.example for required keys.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    '\n\n⚠️  SUPABASE_URL and SUPABASE_ANON_KEY are not set!\n'
    '   Run: flutter run --dart-define-from-file=.env\n'
    '   Copy .env.example → .env and fill in your credentials.\n',
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  debugPrint("Supabase Initialized");
  
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedProfile = prefs.getBool('hasCompletedProfile') ?? false;

  // Set global system UI overlays
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AshaSahyog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
      builder: (context, child) {
        return Container(
          color: AppTheme.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Stack(
                children: [
                  child!,
                  Positioned(
                    top: 10,
                    right: 12,
                    child: SafeArea(
                      child: Material(
                        type: MaterialType.transparency,
                        child: const TtsButton(tooltip: 'Toggle Voice Screen Reader'),
                      ),
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
