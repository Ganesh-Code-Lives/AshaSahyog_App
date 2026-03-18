import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'personal_details.dart';
import 'intro_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    // Optional artificial delay for a smooth effect
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      bool profileCompleted = false;
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('has_completed_profile')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && data['has_completed_profile'] == true) {
          profileCompleted = true;
        }
      } catch (e) {
        print("Failed to fetch profile: $e");
      }

      if (profileCompleted) {
        _navigateToHome();
      } else {
        _navigateToPersonalDetails(user.email ?? '');
      }
    } else {
      _navigateToIntro();
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _navigateToPersonalDetails(String email) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => PersonalDetails(email: email)),
      (route) => false,
    );
  }

  void _navigateToIntro() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IntroScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Can add a logo here. For now, a spinner
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'AshaSahyog',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
