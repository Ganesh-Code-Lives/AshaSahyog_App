import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';
import '../services/tts_service.dart';
import '../main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  bool isLastPage = false;

  late AnimationController _ringController;
  late AnimationController _baseController;
  late Animation<double> _baseScale;
  late Animation<double> _baseFade;

  late AnimationController _ctaController;
  late Animation<double> _ctaOpacity;
  late Animation<Offset> _ctaSlide;
  late Animation<double> _ctaScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTtsButton.value = false;
    });

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _baseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _baseScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _baseController, curve: Curves.elasticOut),
    );
    _baseFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _baseController, curve: Curves.easeIn),
    );

    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _ctaOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctaController, curve: Curves.easeOutCubic),
    );
    _ctaSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctaController, curve: Curves.easeOutCubic),
    );
    _ctaScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.03).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 40),
    ]).animate(_ctaController);

    _baseController.forward();
  }

  @override
  void dispose() {
    showTtsButton.value = true;
    _ringController.dispose();
    _baseController.dispose();
    _ctaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _skipOnboarding() {
    TTSService().speakFeedback(
      'Starting AshaSahyog',
      hiMessage: 'आशा सहयोग शुरू किया जा रहा है',
      mrMessage: 'आशा सहयोग सुरू करत आहे',
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF), // Light purple background
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
            
            // Page View
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                final wasLast = isLastPage;
                setState(() {
                  isLastPage = index == 3;
                });
                
                if (isLastPage && !wasLast) {
                  _ctaController.reset();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && isLastPage) {
                      _ctaController.forward();
                    }
                  });
                } else if (!isLastPage) {
                  _ctaController.reset();
                }
              },
              children: [
                _buildFirstPage(),
                _buildPage(
                  imagePath: 'assets/images/onboarding_phone.png',
                  title: 'Everything You Need,\nAll in One Place',
                  subtitle: 'Access important services and information\neasily, anytime, anywhere.',
                ),
                _buildPage(
                  imagePath: 'assets/images/onboarding_hospital.png',
                  title: 'Find Help Around You',
                  subtitle: 'Locate nearby hospitals, clinics and\nessential services in just a few taps.',
                ),
                _buildPage(
                  imagePath: 'assets/images/onboarding_bell.png',
                  title: 'Stay Updated,\nStay Ahead',
                  subtitle: 'Get reminders, important updates and\nnever miss what matters to you.',
                ),
              ],
            ),

            // Top right Skip Button
            if (!isLastPage)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF5B1685),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFF5B1685),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Navigation
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: isLastPage
                  ? _buildGetStartedButton()
                  : Center(
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: 4,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: Colors.white,
                          dotColor: Colors.white54,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFirstPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Logo Image Composition
          SizedBox(
            height: 300,
            width: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base Image (Inner) with Fade & Scale Animation
                FadeTransition(
                  opacity: _baseFade,
                  child: ScaleTransition(
                    scale: _baseScale,
                    child: Image.asset(
                      'assets/bases.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                      },
                    ),
                  ),
                ),
                // Ring Image (Outer Border) with Continuous Rotation
                RotationTransition(
                  turns: _ringController,
                  child: Image.asset(
                    'assets/ring.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Title
          const Text(
            'AshaSahyog',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C), // Deep Purple
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle 1
          Text(
            'Support. Empower. Together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Line
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle 2
          Text(
            'A single platform to help you access\ngovernment schemes, healthcare,\ndocuments and support services.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Image with Pop-in Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              height: 300,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C), // Deep Purple
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return AnimatedBuilder(
      animation: _ctaController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _ctaOpacity,
          child: SlideTransition(
            position: _ctaSlide,
            child: Transform.scale(
              scale: _ctaScale.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.5 * _ctaOpacity.value),
                      blurRadius: 20 * _ctaOpacity.value,
                      spreadRadius: 2 * _ctaOpacity.value,
                      offset: Offset(0, 8 * _ctaOpacity.value),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _skipOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED), // Main Purple
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Let's Get Started",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}


