import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import 'about_page.dart';

// ✅ අලුතින් හදපු Backup Settings Card එක මෙතනට Import කරලා තියෙනවා
import '../widgets/backup_settings_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ✅ ලොකු _backupNotes සහ _restoreNotes functions මෙතනින් සම්පූර්ණයෙන්ම ඉවත් කර ඇත. (ඒවා දැන් තියෙන්නේ BackupService එකෙයි)

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.appColor;

    final List<Color> accentColors = [
      const Color.fromARGB(255, 255, 31, 188), // Pink
      const Color.fromARGB(255, 255, 251, 0),
      const Color.fromARGB(255, 158, 2, 189), // Purple
      const Color.fromARGB(255, 13, 17, 255), // Blue
      const Color.fromARGB(255, 28, 255, 179), // Green
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.8),
              const Color(0xFF121212) // Dark fade
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // ==========================================
              // SECTION 1: THEME COLOR
              // ==========================================
              _buildSectionHeader('THEME COLOR'),

              Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: accentColors.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 15),
                        itemBuilder: (context, index) {
                          final color = accentColors[index];

                          bool isSelected =
                              primaryColor.toARGB32() == color.toARGB32();
                          bool isWhite = color == Colors.white;

                          return GestureDetector(
                            onTap: () => themeProvider.changeAppColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isWhite ? Colors.black : Colors.white)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: isSelected
                                  ? Icon(Icons.check,
                                      color:
                                          isWhite ? Colors.black : Colors.white,
                                      size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================
              // SECTION 2: WALLPAPER
              // ==========================================
              _buildSectionHeader('WALLPAPER'),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Custom Upload Option (+)
                    _buildWallpaperOption(context, themeProvider, 'Upload',
                        icon: Icons.add_photo_alternate),

                    // Preset: Sakura
                    _buildWallpaperOption(context, themeProvider, 'Sakura',
                        assetPath: 'assets/images/sakura.png'),

                    // Preset: Starry Sky
                    _buildWallpaperOption(context, themeProvider, 'Starry Sky',
                        assetPath: 'assets/images/starry_sky.png'),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================
              // SECTION 3: ANIMATION
              // ==========================================
              _buildSectionHeader('ANIMATION EFFECTS'),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAnimOption(
                          context, 'None', Icons.block, themeProvider),
                      _buildAnimOption(
                          context, 'Snow', Icons.ac_unit, themeProvider),
                      _buildAnimOption(context, 'Sakura', Icons.local_florist,
                          themeProvider),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==========================================
              // SECTION 4: DATA & BACKUP (CLEANED UP)
              // ==========================================
              _buildSectionHeader('DATA'),

              // ✅ මෙන්න අලුතින් හදපු Widget එක (ලොකු කෝඩ් එක වෙනුවට මේ පේළිය පමණක් ප්‍රමාණවත්)
              const BackupSettingsCard(),

              const SizedBox(height: 25),

              // ==========================================
              // SECTION 5: OTHER
              // ==========================================
              _buildSectionHeader('OTHER'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.white.withValues(alpha: 0.1),
                child: _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About YumeMemo',
                  subtitle: 'privacy policy',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutPage()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
        ),
      ),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildAnimOption(BuildContext context, String value, IconData icon,
      ThemeProvider themeProvider) {
    final isSelected = themeProvider.animationType == value;
    final primaryColor = themeProvider.appColor;

    return GestureDetector(
      onTap: () => themeProvider.changeAnimation(value),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperOption(
      BuildContext context, ThemeProvider provider, String title,
      {IconData? icon, String? assetPath}) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () async {
          if (icon != null) {
            FilePickerResult? result =
                await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null) {
              provider.setCustomWallpaper(result.files.single.path!);
            }
          } else if (assetPath != null) {
            provider.setCustomWallpaper(assetPath, isAsset: true);
          }
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(15),
                  image: assetPath != null
                      ? DecorationImage(
                          image: AssetImage(assetPath), fit: BoxFit.cover)
                      : null,
                  border: Border.all(color: Colors.grey.shade700)),
              child: icon != null
                  ? Icon(icon, color: Colors.white, size: 28)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 11))
          ],
        ),
      ),
    );
  }
}
