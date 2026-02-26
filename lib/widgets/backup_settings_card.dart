import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../providers/note_provider.dart';

class BackupSettingsCard extends StatelessWidget {
  const BackupSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withValues(alpha: 0.1),
      child: Column(
        children: [
          // Google Drive / Local Backup Button
          _buildSettingsTile(
            context,
            icon: Icons.backup_outlined,
            title: 'Backup to Drive/Local',
            subtitle: 'Export styles, colors & notes',
            color: Colors.blue,
            onTap: () => BackupService.backupNotes(context),
          ),
          Divider(
              height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.2)),

          // Import Button
          _buildSettingsTile(
            context,
            icon: Icons.download_outlined,
            title: 'Import Notes',
            subtitle: 'Restore from Google Drive',
            color: Colors.green,
            onTap: () => BackupService.restoreNotes(context),
          ),
          Divider(
              height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.2)),

          // Delete All Button
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Delete All Notes',
            subtitle: 'Cannot be undone',
            color: Colors.redAccent,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
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
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Delete Everything?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Are you sure you want to delete ALL notes permanently? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final provider =
                  Provider.of<NoteProvider>(context, listen: false);
              await provider.deleteAllPermanently();

              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notes deleted permanently! ✨')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
