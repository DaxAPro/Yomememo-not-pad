import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  String _versionInfo = 'Loading...';

  // ✅ වර්තමාන වර්ෂය ස්වයංක්‍රීයව ලබා ගැනීම (2025, 2026, 2027...)
  final int _currentYear = DateTime.now().year;

  final Uri _privacyPolicyUrl = Uri.parse(
      'https://medium.com/@yonalsolutions/privacy-policy-for-yumememo-305fb7c25dc5');

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();

    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = TweenSequence<Color?>(
      [
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(
            begin: const Color(0xFFFAFAFA),
            end: const Color(0xFFE3F2FD),
          ),
        ),
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(
            begin: const Color(0xFFE3F2FD),
            end: const Color(0xFFFCE4EC),
          ),
        ),
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(
            begin: const Color(0xFFFCE4EC),
            end: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _versionInfo = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(_privacyPolicyUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Privacy Policy URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          appBar: AppBar(
            title: const Text('About YumeMemo'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          body: child,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon.png',
                  height: 100,
                  width: 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'YumeMemo',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            'Version $_versionInfo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),

          const Text(
            'Your aesthetic space for thoughts, dreams, and ideas. Simple, secure, and beautiful.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),

          const Divider(height: 40, thickness: 1),

          const Text(
            'Privacy & Security',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 15),

          _buildFeatureTile(
            icon: Icons.cloud_off_rounded,
            title: 'Offline First',
            subtitle: 'Your notes stay on your device.',
            iconColor: Colors.blue,
          ),
          _buildFeatureTile(
            icon: Icons.mic_none_rounded,
            title: 'Voice Typing',
            subtitle: 'Uses microphone only when you tap it.',
            iconColor: Colors.redAccent,
          ),
          _buildFeatureTile(
            icon: Icons.security_rounded,
            title: 'Secure',
            subtitle: 'We do not collect your personal notes.',
            iconColor: Colors.green,
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 2,
            shadowColor: Colors.teal.withValues(alpha: 0.2),
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.policy, color: Colors.teal),
              ),
              title: const Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Read our full policy'),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: _launchUrl,
            ),
          ),

          const SizedBox(height: 40),

          // ✅ FIX: මෙන්න මෙතන තමයි Auto Update වෙන Copyright එක තියෙන්නේ
          Center(
              child: Text(
                  'Copyright © $_currentYear YumeMemo Developers.\nAll rights reserved.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12))),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
