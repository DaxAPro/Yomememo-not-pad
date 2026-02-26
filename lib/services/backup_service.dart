import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';

class BackupService {
  // ==========================================
  // 1. සියලුම Notes Backup කිරීම (All Notes)
  // ==========================================
  static Future<void> backupNotes(BuildContext context) async {
    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      final notes = noteProvider.notes;

      // Note data (with colors and rich text) converting to JSON String
      String jsonString = jsonEncode(notes.map((e) => e.toJson()).toList());

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/yumememo_backup.json');

      await file.writeAsString(jsonString);

      // මෙතනින් Share Dialog එක Open වෙනවා
      if (context.mounted) {
        await Share.shareXFiles([XFile(file.path)],
            text: 'YumeMemo Backup File - Save to Google Drive');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Backup Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================
  // 2. තනි Note එකක් පමණක් Share/Backup කිරීම (Single Note)
  // ==========================================
  static Future<void> backupSingleNote(BuildContext context, Note note) async {
    try {
      // මෙහිදී එක Note එකක් පමණක් List එකක් ලෙස යවයි (Restore function එකට ගැලපෙන පරිදි)
      String jsonString = jsonEncode([note.toJson()]);

      final directory = await getApplicationDocumentsDirectory();

      // Note එකේ නමෙන් File එක සෑදීම
      String safeTitle = note.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      if (safeTitle.isEmpty) safeTitle = 'untitled_note';

      final file = File('${directory.path}/yumememo_$safeTitle.json');

      await file.writeAsString(jsonString);

      if (context.mounted) {
        await Share.shareXFiles([XFile(file.path)],
            text: 'YumeMemo Note: ${note.title} - Save to Google Drive');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to export note: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================
  // 3. Notes Restore කිරීම (Import Notes)
  // ==========================================
  static Future<void> restoreNotes(BuildContext context) async {
    try {
      // මෙතනින් System File Picker එක Open වෙනවා
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        List<dynamic> jsonList = jsonDecode(content);

        if (!context.mounted) return;
        final noteProvider = Provider.of<NoteProvider>(context, listen: false);

        int count = 0;
        for (var jsonItem in jsonList) {
          Map<String, dynamic> noteMap = jsonItem;
          noteMap.remove('_id'); // ID conflict එකක් නොවෙන්න
          Note newNote = Note.fromJson(noteMap);
          await noteProvider.addNote(newNote);
          count++;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Successfully restored $count notes with styles & colors!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore Failed: File might be corrupted.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
