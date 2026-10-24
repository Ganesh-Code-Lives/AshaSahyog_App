import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'personal_details.dart';
import 'intro_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start fade-in immediately
    _fadeController.forward();
    _checkUser();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkUser() async {
    final startTime = DateTime.now();
    bool profileCompleted = false;
    String? userEmail;
    bool isLoggedIn = false;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        isLoggedIn = true;
        userEmail = user.email;
        try {
          final data = await Supabase.instance.client
              .from('profiles')
              .select('has_completed_profile')
              .eq('id', user.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 4));

          if (data != null && data['has_completed_profile'] == true) {
            profileCompleted = true;
          }
        } catch (e) {
          debugPrint("Failed to fetch profile during splash: $e");
          // If check fails due to network/timeout, allow logged-in user to proceed to home
          profileCompleted = true;
        }
      }
    } catch (e) {
      debugPrint("Error checking auth status in splash: $e");
    } finally {
      // Ensure splash shows for a smooth duration (minimum 2 seconds)
      final elapsed = DateTime.now().difference(startTime);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (mounted) {
        try {
          await _fadeController.reverse();
        } catch (_) {}

        if (mounted) {
          // Based on auth results, navigate to the correct screen
          if (isLoggedIn) {
            if (profileCompleted) {
              _navigateToHome();
            } else {
              _navigateToPersonalDetails(userEmail ?? '');
            }
          } else {
            _navigateToIntro();
          }
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _navigateToPersonalDetails(String email) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => PersonalDetails(email: email),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _navigateToIntro() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const IntroScreen(),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // 1. Theme-matching Background Gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.purpleVeryLight,
                    AppTheme.background,
                    AppTheme.surface,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // 2. Soft Theme-matching Vignette
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),

            // 3. Center Content with Logo Glow (No Text)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.15), // Theme purple glow
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8), // Inner highlight
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const CustomLoadingIndicator(size: 280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}