import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// --- දිදුලන කුඩු (Dust Particles) සඳහා ක්ලාස් එක ---
class DustParticle {
  double x;
  double y;
  double life; // 1.0 සිට 0.0 දක්වා අඩුවේ
  double dx;
  double dy;
  double size;

  DustParticle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    this.life = 1.0,
  });
}

class ButterflyLogoAnimation extends StatefulWidget {
  final String text;
  final double fontSize;

  const ButterflyLogoAnimation({
    super.key,
    required this.text,
    this.fontSize = 26,
  });

  @override
  State<ButterflyLogoAnimation> createState() => _ButterflyLogoAnimationState();
}

class _ButterflyLogoAnimationState extends State<ButterflyLogoAnimation>
    with TickerProviderStateMixin {
  late AnimationController _infiniteLoopController;
  late AnimationController _wingFlapController;
  late Animation<double> _loopPathAnimation;
  late Animation<double> _wingAngleAnimation;

  // Particles පාලනය කිරීම සඳහා
  late Ticker _particleTicker;
  final List<DustParticle> _particles = [];
  Offset _currentButterflyPos = Offset.zero;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 1. අනන්තය (∞) මාර්ගයේ ගමන් කිරීම (ඉතා සෙමින් - තත්පර 18)
    _infiniteLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _loopPathAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_infiniteLoopController);

    // 2. පියාපත් සැලීම (මෘදු ලෙස)
    _wingFlapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _wingAngleAnimation = Tween<double>(begin: 0.1, end: 1.1).animate(
      CurvedAnimation(parent: _wingFlapController, curve: Curves.easeInOut),
    );

    // 3. දිදුලන කුඩු (Particles) නිර්මාණය කරන Ticker එක
    _particleTicker = createTicker((elapsed) {
      _updateParticles();
    });
    _particleTicker.start();

    // සමනලයාගේ වර්තමාන ස්ථානය නිරන්තරයෙන් ලබා ගැනීම
    _infiniteLoopController.addListener(() {
      setState(() {
        _currentButterflyPos = _getInfinityPosition(_loopPathAnimation.value);
      });
    });
  }

  @override
  void dispose() {
    _infiniteLoopController.dispose();
    _wingFlapController.dispose();
    _particleTicker.dispose();
    super.dispose();
  }

  // --- Particle Physics (කුඩු පහළට වැටීම සහ මැකී යාම) ---
  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.x += particle.dx;
        particle.y += particle.dy;
        particle.life -= 0.015;
      }

      _particles.removeWhere((p) => p.life <= 0);

      if (_random.nextDouble() > 0.4) {
        _particles.add(DustParticle(
          x: _currentButterflyPos.dx + (_random.nextDouble() * 10 - 5),
          y: _currentButterflyPos.dy + (_random.nextDouble() * 10 - 5),
          dx: (_random.nextDouble() - 0.5) * 0.5,
          dy: _random.nextDouble() * 1.5 + 0.5,
          size: _random.nextDouble() * 2.5 + 1.0,
        ));
      }
    });
  }

  // --- අනන්තය (∞) හැඩයේ ඛණ්ඩාංක ---
  Offset _getInfinityPosition(double angle) {
    const double scale = 85.0;
    const double a = 0.45;

    double x = (scale * cos(angle)) / (1 + sin(angle) * sin(angle));
    double y =
        (scale * sin(angle) * cos(angle)) / (1 + sin(angle) * sin(angle));

    return Offset(x, y * a);
  }

  // --- දිදුලන සමනලයා නිර්මාණය කිරීම ---
  Widget _buildGlowingButterfly() {
    return AnimatedBuilder(
      animation: _wingAngleAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // වම් පියාපත
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.003)
                ..rotateY(_wingAngleAnimation.value),
              alignment: Alignment.centerRight,
              child: Container(
                width: 16,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.5)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
            // සමනලයාගේ ඇඟ (මෙහි තමයි Const error එක තිබුණේ)
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                // ✅ දැන් මෙතනට 'const' එකතු කරලා තියෙනවා
                boxShadow: const [
                  BoxShadow(color: Colors.white, blurRadius: 6, spreadRadius: 2)
                ],
              ),
            ),
            // දකුණු පියාපත
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.003)
                ..rotateY(-_wingAngleAnimation.value),
              alignment: Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                    bottomLeft: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1. යටින් තියෙන අකුරු (Shadow එකත් සමග)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontFamily: 'Pacifico',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 12.0,
                  color: Colors.white.withValues(alpha: 0.4),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),

        // 2. දිදුලන කුඩු (Dust Particles Layer)
        CustomPaint(
          painter: DustPainter(particles: _particles),
        ),

        // 3. සමනලයාගේ Animation එක
        AnimatedBuilder(
          animation: _infiniteLoopController,
          builder: (context, child) {
            final double normalizedPath = (_loopPathAnimation.value / (2 * pi));

            bool isBehindText =
                (normalizedPath > 0.33 && normalizedPath < 0.66) ||
                    (normalizedPath > 0.85 || normalizedPath < 0.15);

            return Transform.translate(
              offset: _currentButterflyPos,
              child: Opacity(
                opacity: isBehindText ? 0.2 : 1.0,
                child: _buildGlowingButterfly(),
              ),
            );
          },
        ),

        // 4. සමනලයා පිටුපසින් යද්දී අකුරු උඩින් පෙන්වීමේ Layer එක
        AnimatedBuilder(
          animation: _infiniteLoopController,
          builder: (context, child) {
            final double normalizedPath = (_loopPathAnimation.value / (2 * pi));
            bool shouldCoverButterfly =
                (normalizedPath > 0.33 && normalizedPath < 0.66) ||
                    (normalizedPath > 0.85 || normalizedPath < 0.15);

            return IgnorePointer(
              child: Opacity(
                opacity: shouldCoverButterfly ? 1.0 : 0.0,
                child: child!,
              ),
            );
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontFamily: 'Pacifico',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- දිදුලන කුඩු අඳින CustomPainter එක ---
class DustPainter extends CustomPainter {
  final List<DustParticle> particles;

  DustPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: particle.life)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(
        Offset(size.width / 2 + particle.x, size.height / 2 + particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DustPainter oldDelegate) => true;
}
