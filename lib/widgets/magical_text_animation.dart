import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class MagicalTextAnimation extends StatefulWidget {
  final String text;
  final double fontSize;

  const MagicalTextAnimation({
    super.key,
    required this.text,
    required this.fontSize,
  });

  @override
  State<MagicalTextAnimation> createState() => _MagicalTextAnimationState();
}

class _MagicalTextAnimationState extends State<MagicalTextAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    // Breathing Effect Setup
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slow transition speed
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Breathing Glow Effect (Background)
            Text(
              widget.text,
              style: GoogleFonts.indieFlower(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize,
                  color: Colors.transparent, // Transparent text for glow effect
                  shadows: [
                    Shadow(
                      blurRadius: _breathingAnimation.value, // Glow size
                      color: Colors.white
                          .withValues(alpha: 0.6), // Light white glow
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: _breathingAnimation.value / 2,
                      color: const Color(0xFFFFD700)
                          .withValues(alpha: 0.4), // Light golden glow
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
            // 2. Shimmer Effect (Foreground)
            Shimmer.fromColors(
              baseColor:
                  Colors.white.withValues(alpha: 0.8), // Normal text color
              highlightColor: const Color(0xFFFFE8B8), // Shining golden color
              period: const Duration(seconds: 5), // Animation speed
              child: Text(
                widget.text,
                style: GoogleFonts.indieFlower(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
