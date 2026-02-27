import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const YumeMemoApp());
}

class YumeMemoApp extends StatelessWidget {
  const YumeMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'YumeMemo Notepad',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: themeProvider.appColor),
              useMaterial3: true,
              brightness: Brightness.light,
              // ✅ Transparent වෙනුවට සුදු හෝ ලා පාටක් භාවිතා කර ඇත (Black screen වලක්වන්න)
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.appColor,
                brightness: Brightness.dark,
                surface: Color.alphaBlend(
                  themeProvider.appColor.withValues(alpha: 0.15),
                  const Color(0xFF121212),
                ),
              ),
              useMaterial3: true,
              brightness: Brightness.dark,
              // ✅ Transparent වෙනුවට අඳුරු වර්ණයක් භාවිතා කර ඇත
              scaffoldBackgroundColor: const Color(0xFF121212),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
