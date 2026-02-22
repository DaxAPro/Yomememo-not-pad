import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _appColor = const Color(0xFFE91E63); // Default Pink

  // ✅ App එක Open වෙද්දී Default Animation එක 'Sakura' දාන්න (කැමති නම් 'Snow' දාන්න පුළුවන්)
  String _bgAnimation = 'Sakura';

  // ✅ App එක Open වෙද්දී Default Wallpaper එක 'Sakura' දාන්න
  String? _backgroundImage = 'assets/images/sakura.png';
  bool _isAssetImage = true;

  List<String> _categories = ['Personal', 'Work', 'Ideas', 'Wishlist'];

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get appColor => _appColor;
  Color get accentColor => _appColor;
  String get animationType => _bgAnimation;
  String? get backgroundImage => _backgroundImage;
  bool get isAssetImage => _isAssetImage;
  List<String> get categories => _categories;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveToPrefs();
    notifyListeners();
  }

  void changeAppColor(Color color) {
    _appColor = color;
    _saveToPrefs();
    notifyListeners();
  }

  void changeAccentColor(Color color) {
    changeAppColor(color);
  }

  void changeAnimation(String animationType) {
    _bgAnimation = animationType;
    _saveToPrefs();
    notifyListeners();
  }

  void setCustomWallpaper(String path, {bool isAsset = false}) {
    _backgroundImage = path;
    _isAssetImage = isAsset;
    _saveToPrefs();
    notifyListeners();
  }

  void removeCustomWallpaper() {
    _backgroundImage = null;
    _saveToPrefs();
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeCategory(String category) {
    if (_categories.contains(category)) {
      _categories.remove(category);
      _saveToPrefs();
      notifyListeners();
    }
  }

  _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final colorValue = prefs.getInt('appColor');
    if (colorValue != null) {
      _appColor = Color(colorValue);
    }

    _bgAnimation =
        prefs.getString('bgAnimation') ?? 'Sakura'; // Default: Sakura

    // ✅ Wallpaper එක load වෙද්දී null නම් Sakura දාන්න
    _backgroundImage =
        prefs.getString('backgroundImage') ?? 'assets/images/sakura.png';
    _isAssetImage = prefs.getBool('isAssetImage') ?? true;

    final savedCategories = prefs.getStringList('categories');
    if (savedCategories != null) {
      _categories = savedCategories;
    }

    notifyListeners();
  }

  _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);

    await prefs.setInt('appColor', _appColor.toARGB32());

    await prefs.setString('bgAnimation', _bgAnimation);

    if (_backgroundImage != null) {
      await prefs.setString('backgroundImage', _backgroundImage!);
    } else {
      await prefs.remove('backgroundImage');
    }

    await prefs.setBool('isAssetImage', _isAssetImage);
    await prefs.setStringList('categories', _categories);
  }
}
