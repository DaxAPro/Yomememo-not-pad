import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SnowAnimationWidget extends StatefulWidget {
  const SnowAnimationWidget({super.key});

  @override
  State<SnowAnimationWidget> createState() => _SnowAnimationWidgetState();
}

class _SnowAnimationWidgetState extends State<SnowAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Snowflake> _snowflakes = [];
  double _gravityX = 0;
  StreamSubscription? _accelerometerSubscription;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // ✅ FIX: setState ඉවත් කරන ලදී.
    // AnimationController එක කොහොමත් හැම frame එකේදීම refresh වෙන නිසා
    // මෙතන අගය විතරක් මාරු වුනාම ඇති. මෙය Performance වලට ඉතා හොඳයි.
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        _gravityX = -event.x / 2.0;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    // Size එක වෙනස් වුනොත් විතරක් අලුතින් හදන්න (Performance හොඳයි)
    if (_lastSize != size) {
      _lastSize = size;
      _snowflakes = List.generate(
        50, // හිම කැට ගණන
        (index) => Snowflake(size),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_snowflakes.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          for (var flake in _snowflakes) {
            flake.fall(_gravityX);
          }
          return CustomPaint(
            painter: SnowPainter(_snowflakes),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;

  // ✅ FIX: Paint object එක loop එකෙන් එළියට ගත්තා.
  // දැන් මේක හැදෙන්නේ එක පාරයි. Performance ගොඩක් වැඩි වෙනවා.
  final Paint _paint = Paint()..color = Colors.white.withValues(alpha: 0.8);

  SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var flake in snowflakes) {
      // කලින් තිබුන Paint object එක වෙනුවට උඩ හදපු _paint පාවිච්චි කරනවා
      canvas.drawCircle(Offset(flake.x, flake.y), flake.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Snowflake {
  double x;
  double y;
  double radius;
  double velocityY;
  double velocityX;

  final Size area;

  Snowflake(this.area)
      : x = Random().nextDouble() * area.width,
        y = Random().nextDouble() * area.height,
        radius = Random().nextDouble() * 2 + 1, // ප්‍රමාණය
        velocityY = Random().nextDouble() * 2 + 1, // වේගය
        velocityX = Random().nextDouble() * 0.5 - 0.25;

  void fall(double gravityX) {
    x += velocityX + gravityX;
    y += velocityY;

    if (y > area.height) {
      y = -radius;
      x = Random().nextDouble() * area.width;
    } else if (x < -radius) {
      x = area.width + radius;
    } else if (x > area.width + radius) {
      x = -radius;
    }
  }
}
