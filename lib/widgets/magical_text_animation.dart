import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math; // ගණිතමය සමීකරණ සඳහා

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
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late AnimationController _butterflyController; // සමනලයා සඳහා Controller එක

  @override
  void initState() {
    super.initState();
    // 1. Text Breathing Glow Effect Setup
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // 2. Butterfly Flying Effect Setup (තත්පර 6න් 6ට රවුමක් පියාඹයි)
    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _butterflyController.dispose(); // මතක ඇතිව Controller එක dispose කළ යුතුය
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Animation දෙකම එකවර ක්‍රියාත්මක කරන්න
      animation: Listenable.merge([_breathingController, _butterflyController]),
      builder: (context, child) {
        // --- සමනලයා පියාඹන පථය (Flight Path) සකස් කිරීම ---
        double progress = _butterflyController.value;

        // X අක්ෂය ඔස්සේ වමට සහ දකුණට යාම (අකුරු වටේට)
        double dx = math.sin(progress * math.pi * 2) * 80;

        // Y අක්ෂය ඔස්සේ ඉහළට සහ පහළට යාම (Figure-8 හැඩය)
        double dy = math.cos(progress * math.pi * 4) * 15;

        // පියාඹන දිශාවට අනුව හැරීම (Rotation)
        double angle = math.cos(progress * math.pi * 4) * 0.3;

        return Stack(
          clipBehavior: Clip.none, // සමනලයා කොටුවෙන් පිටතට ගියත් පෙනීමට
          alignment: Alignment.center,
          children: [
            // 1. Breathing Glow Effect (Background)
            Text(
              widget.text,
              style: GoogleFonts.indieFlower(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      blurRadius: _breathingAnimation.value,
                      color: Colors.white.withValues(alpha: 0.6),
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: _breathingAnimation.value / 2,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Shimmer Effect (Foreground Text)
            Shimmer.fromColors(
              baseColor: Colors.white.withValues(alpha: 0.8),
              highlightColor: const Color(0xFFFFE8B8),
              period: const Duration(seconds: 5),
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

            // 3. ලස්සනට පියාඹන සමනලයා (Butterfly 🦋)
            Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: angle,
                child: Text(
                  '🦋',
                  style: TextStyle(
                      fontSize: widget.fontSize * 0.7, // සමනලයාගේ ප්‍රමාණය
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 10,
                        )
                      ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
