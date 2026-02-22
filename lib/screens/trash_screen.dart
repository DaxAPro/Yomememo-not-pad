import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card_widget.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  void _showTrashDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(note.title),
          content: const Text('What would you like to do with this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Restore'),
              onPressed: () {
                Provider.of<NoteProvider>(context, listen: false)
                    .restoreFromTrash(note);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete Permanently',
                  style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<NoteProvider>(context, listen: false)
                    .deletePermanently(note.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash 🗑️')),
      body: Consumer<NoteProvider>(builder: (context, noteProvider, child) {
        if (noteProvider.trashedNotes.isEmpty) {
          return const Center(
            child: Text(
              'Trash is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(10.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: noteProvider.trashedNotes.length,
          itemBuilder: (context, index) {
            final note = noteProvider.trashedNotes[index];
            return GestureDetector(
              onTap: () => _showTrashDialog(context, note),
              child: NoteCard(note: note),
            );
          },
        );
      }),
    );
  }
}
