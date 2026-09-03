import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'asha_assistant_sheet.dart';

class AshaAssistantButton extends StatefulWidget {
  final Function(String route) onNavigate;

  const AshaAssistantButton({super.key, required this.onNavigate});

  @override
  State<AshaAssistantButton> createState() => _AshaAssistantButtonState();
}

class _AshaAssistantButtonState extends State<AshaAssistantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Slower, more subtle pulse
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AshaAssistantSheet(onNavigate: widget.onNavigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openAssistant,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, 
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.25), 
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4), 
              ),
            ],
          ),
          child: Stack(
            children: [
              // Avatar
              ClipOval(
                child: Center(
                  child: Transform.scale(
                    scale: 1.05, // Zoom in to completely crop out the image's built-in white border
                    child: Image.asset(
                      'assets/images/asha_assistant.png',
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              // Online Indicator
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
