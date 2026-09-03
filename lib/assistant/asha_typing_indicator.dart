import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AshaTypingIndicator extends StatefulWidget {
  const AshaTypingIndicator({super.key});

  @override
  State<AshaTypingIndicator> createState() => _AshaTypingIndicatorState();
}

class _AshaTypingIndicatorState extends State<AshaTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = (_controller.value * 3 - index).clamp(0.0, 1.0);
              final opacity = val > 0.5 ? 1.0 - (val - 0.5) * 2 : val * 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.3 + (opacity * 0.7)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
