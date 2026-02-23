import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../pages/settings_page.dart';
import 'trash_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    // ✅ Video load mattu auto-play madalu
    _videoController =
        VideoPlayerController.asset('assets/videos/night_sky.mp4')
          ..initialize().then((_) {
            _videoController.setLooping(true);
            _videoController.setVolume(0.0);
            _videoController.play();
            setState(() {});
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _showAddFolderDialog(BuildContext context) {
    final TextEditingController folderController = TextEditingController();
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: folderController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter folder name...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (folderController.text.isNotEmpty) {
                noteProvider.addCategory(folderController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, String category) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              noteProvider.deleteCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ Color eka Dark karana function eka (Text pehediliwa penna)
  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Lightness eka 0.25 kin adu karanawa (Thada paatak labaganna)
    if (hsl.lightness > 0.4) {
      return hsl
          .withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0))
          .toColor();
    }
    return color; // Kalinma dark nam wenas karanne na
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);

    final backgroundColor = Color.alphaBlend(
      themeProvider.appColor.withValues(alpha: 0.15),
      Colors.white,
    );

    final primaryColor = themeProvider.appColor;
    // ✅ Dark karapu color eka gannawa text walatai icon walatai
    final textAndIconColor = _getDarkerColor(primaryColor);

    return Drawer(
      backgroundColor: backgroundColor,
      child: Container(
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Container(
              color: primaryColor.withValues(alpha: 0.9),
              child: Stack(
                children: [
                  if (_videoController.value.isInitialized)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  UserAccountsDrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    accountName: const Text(
                      "YumeMemo",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IndieFlower',
                        color: Colors.white,
                      ),
                    ),
                    accountEmail: const Text(
                      "Capture your dreams ✨",
                      style: TextStyle(color: Colors.white70),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit_note,
                          size: 40, color: textAndIconColor),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Menu Items List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.notes,
                    text: 'All Notes',
                    isSelected: noteProvider.selectedCategory == 'All',
                    baseColor: primaryColor,
                    darkColor: textAndIconColor,
                    onTap: () {
                      noteProvider.setCategory('All');
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(thickness: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FOLDERS',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showAddFolderDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(
                                  alpha: 0.2), // Background eka light
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add,
                                size: 20,
                                color: textAndIconColor), // Icon eka dark
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...noteProvider.availableCategories
                      .where((cat) => cat != 'All')
                      .map((category) {
                    return _buildMenuItem(
                      icon: Icons.folder_open,
                      text: category,
                      isSelected: noteProvider.selectedCategory == category,
                      baseColor: primaryColor,
                      darkColor: textAndIconColor,
                      onTap: () {
                        noteProvider.setCategory(category);
                        Navigator.pop(context);
                      },
                      onLongPress: () =>
                          _showDeleteFolderDialog(context, category),
                    );
                  }),
                  const Divider(thickness: 1),
                  _buildMenuItem(
                    icon: Icons.delete_outline,
                    text: 'Trash',
                    isSelected: false,
                    baseColor: Colors.redAccent,
                    darkColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrashScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    text: 'Settings',
                    isSelected: false,
                    baseColor: Colors.grey.shade700,
                    darkColor: Colors.grey.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required Color baseColor,
    required Color darkColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? darkColor : darkColor.withValues(alpha: 0.7),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? darkColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      // Background (tileColor) eka nam lapaata baseColor ekamay, e nisa text eka highlight wenawa
      tileColor: isSelected ? baseColor.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
