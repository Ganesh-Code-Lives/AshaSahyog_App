import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kfrgkhhsnyqqvqtwimbx.supabase.co', // TODO: Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmcmdraGhzbnlxcXZxdHdpbWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwNTEyNTgsImV4cCI6MjA4NjYyNzI1OH0.pOSmrezElecOcCm6ANJ81nO_WN9wnc_EdLq1mwAmXZU', // TODO: Replace with your Supabase Anon Key
  );
  print("Supabase Initialized");
  
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedProfile = prefs.getBool('hasCompletedProfile') ?? false;

  // Set global system UI overlays
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'AshaSahyog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: session != null ? const SplashScreen() : const IntroScreen(),
    );
  }
}
