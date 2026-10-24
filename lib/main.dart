import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';

import 'providers/asha_assistant_provider.dart';

// Global state to control TTS button visibility
final ValueNotifier<bool> showTtsButton = ValueNotifier(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Error Handling & Error Boundary ────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Framework Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error\n$stack');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFAF7FF),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF7C3AED), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B2E)),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode ? details.exceptionAsString() : 'An unexpected issue occurred. Please restart or try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize notifications safely
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("NotificationService initialization error: $e");
  }
  
  // ── Supabase credentials ──────────────────────────────────────────
  // Values can be injected at build/run time via:
  //   flutter run --dart-define-from-file=.env
  // or GitHub Actions secrets / --dart-define flags.
  const envSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  final supabaseUrl = envSupabaseUrl.isNotEmpty
      ? envSupabaseUrl
      : 'https://kfrgkhhsnyqqvqtwimbx.supabase.co';
  final supabaseAnonKey = envSupabaseAnonKey.isNotEmpty
      ? envSupabaseAnonKey
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmcmdraGhzbnlxcXZxdHdpbWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwNTEyNTgsImV4cCI6MjA4NjYyNzI1OH0.pOSmrezElecOcCm6ANJ81nO_WN9wnc_EdLq1mwAmXZU';

  // Initialize Supabase safely
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint("Supabase Initialized");
  } catch (e) {
    debugPrint("Supabase Initialization Error: $e");
  }
  
  // Set global system UI overlays
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AshaAssistantProvider()),
      ],
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
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
