import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingIndicator extends StatefulWidget {
  final double size;

  const CustomLoadingIndicator({super.key, this.size = 150.0});

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 5 seconds for a slow, smooth, full 360 rotation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(); // Continually repeats the animation
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the widget tree
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Circular Ring - Rotating
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              return Transform.rotate(
                angle: -_controller.value * 2 * math.pi,
                child: child,
              );
            },
            child: Image.asset(
              'assets/ring.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              // Adding error builder to prevent crashes if asset is missing
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.error_outline, color: Colors.red),
            ),
          ),
          
          // Inner Logo - Fixed
          Image.asset(
            'assets/bases.png',
            width: widget.size * 0.85, // Increased inner scale slightly
            height: widget.size * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.error, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
