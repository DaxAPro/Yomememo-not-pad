import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SakuraAnimationWidget extends StatefulWidget {
  const SakuraAnimationWidget({super.key});

  @override
  State<SakuraAnimationWidget> createState() => _SakuraAnimationWidgetState();
}

class _SakuraAnimationWidgetState extends State<SakuraAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<SakuraPetal> _petals = [];
  double _gravityX = 0; // ෆෝන් එකේ ඇලවීම (X අක්ෂය)
  StreamSubscription? _accelerometerSubscription;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Smooth animation
    )..repeat();

    // ✅ Accelerometer හරහා ෆෝන් එකේ ඇලවීම ලබා ගැනීම
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // event.x අගය ඍණ (-) කළ විට ස්වභාවික පැත්තට වැටේ
          // 2.0 න් බෙදුවේ වේගය පාලනය කරන්න
          _gravityX = -event.x / 2.0;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Screen Size එක වෙනස් වුනොත් හෝ මුලින්ම Load වෙද්දී Petals අලුතින් හදනවා
    final size = MediaQuery.of(context).size;
    if (_lastSize != size) {
      _lastSize = size;
      _petals = List.generate(
        30, // මල් පෙති ගණන
        (index) => SakuraPetal(size),
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
    // Screen Size එකක් නැත්නම් මුකුත් පෙන්නන්න එපා (Error වළක්වන්න)
    if (_petals.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      // Touch වලට බාධා නොවීමට
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          for (var petal in _petals) {
            petal.fall(_gravityX); // ගුරුත්වාකර්ෂණය පාස් කරනවා
          }
          return CustomPaint(
            painter: SakuraPainter(_petals),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class SakuraPainter extends CustomPainter {
  final List<SakuraPetal> petals;
  SakuraPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (var petal in petals) {
      final textSpan = TextSpan(
        text: '🌸',
        style: TextStyle(
          fontSize: petal.fontSize,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      // පෙත්ත තියෙන තැනට Canvas එක ගෙනියනවා
      canvas.translate(petal.x, petal.y);
      // පෙත්ත කරකවනවා
      canvas.rotate(petal.rotation);
      // පෙත්ත අඳිනවා (මැදට සෙන්ටර් කරලා)
      textPainter.paint(
          canvas, Offset(-petal.fontSize / 2, -petal.fontSize / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SakuraPetal {
  double x;
  double y;
  double fontSize;
  double velocityY;
  double velocityX;
  double sway;
  double rotation;
  double rotationSpeed;

  final Size area;

  SakuraPetal(this.area)
      : x = Random().nextDouble() * area.width,
        y = Random().nextDouble() * area.height,
        fontSize = Random().nextDouble() * 15 + 10,
        velocityY = Random().nextDouble() * 1.5 + 0.5, // වැටෙන වේගය
        velocityX = Random().nextDouble() * 0.5 - 0.25,
        sway = Random().nextDouble() * 2 * pi,
        rotation = Random().nextDouble() * 2 * pi,
        rotationSpeed = Random().nextDouble() * 0.05 - 0.025;

  void fall(double gravityX) {
    sway += 0.05;
    rotation += rotationSpeed;

    // පැද්දීම + ෆෝන් එකේ ඇලවීම (gravityX)
    x += sin(sway) * 0.5 + velocityX + gravityX;
    y += velocityY;

    // තිරයෙන් එළියට ගියොත් ආපහු උඩට ගේනවා
    if (y > area.height + fontSize) {
      y = -fontSize;
      x = Random().nextDouble() * area.width;
    }
    // වම් පැත්තෙන් එළියට ගියොත් දකුණෙන් එන්න
    else if (x < -fontSize) {
      x = area.width + fontSize;
    }
    // දකුණු පැත්තෙන් එළියට ගියොත් වමෙන් එන්න
    else if (x > area.width + fontSize) {
      x = -fontSize;
    }
  }
}
