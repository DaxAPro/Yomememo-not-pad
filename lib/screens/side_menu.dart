import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  // අලුත් Folder එකක් හදන Dialog එක
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

  // Folder එකක් Delete කරන Dialog එක
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);

    // ✅ Background Color Logic:
    // මුළු Menu එකම ලාවට පාට වෙන්න (Tint) හදනවා.
    final backgroundColor = Color.alphaBlend(
      themeProvider.appColor.withValues(alpha: 0.15), // 15% Main Color
      Colors.white, // 85% White
    );

    final primaryColor = themeProvider.appColor;

    return Drawer(
      // ✅ වැදගත්ම තැන: Drawer එකේ පාට මෙතනින් දානවා
      backgroundColor: backgroundColor,
      child: Container(
        color: backgroundColor, // මෙතනත් පාට දානවා ආරක්ෂාවට
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section (උඩ කොටස)
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color:
                    primaryColor.withValues(alpha: 0.9), // Header එක තද පාටින්
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
                child: Icon(Icons.edit_note, size: 40, color: primaryColor),
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
                    color: primaryColor,
                    onTap: () {
                      noteProvider.setCategory('All');
                      Navigator.pop(context);
                    },
                  ),

                  const Divider(thickness: 1),

                  // ✅ FOLDERS HEADER with (+) BUTTON
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
                        // ✅ (+) Add Folder Button
                        InkWell(
                          onTap: () => _showAddFolderDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                Icon(Icons.add, size: 20, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Folder List
                  // 'All' එක හැර අනිත් Folders පෙන්නනවා
                  ...noteProvider.availableCategories
                      .where((cat) => cat != 'All')
                      .map((category) {
                    return _buildMenuItem(
                      icon: Icons.folder_open,
                      text: category,
                      isSelected: noteProvider.selectedCategory == category,
                      color: primaryColor,
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
                    color: Colors.redAccent,
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
                    color: Colors.grey.shade700,
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

            // Footer Version
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "v1.0.0",
                  style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6), fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Menu Item
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? color : color.withValues(alpha: 0.7),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      // Select වුනාම පෙන්නන Background එක
      tileColor: isSelected ? color.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
