import 'package:flutter/material.dart';

class GlowBackground extends StatelessWidget {
  final Color color;
  final double size;
  const GlowBackground({super.key, required this.color, this.size = 300});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
