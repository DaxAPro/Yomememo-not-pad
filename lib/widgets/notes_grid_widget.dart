import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import 'note_card_widget.dart';

class NotesGridWidget extends StatelessWidget {
  final List<Note> notes;
  final String searchQuery;
  final bool isDarkMode;
  final Function(Note) onNoteTap;
  final Function(Note) onNoteLongPress;

  const NotesGridWidget({
    super.key,
    required this.notes,
    required this.searchQuery,
    required this.isDarkMode,
    required this.onNoteTap,
    required this.onNoteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Note එකක්වත් නැති විට පෙන්වන තිරය (Empty State)
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 80, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No notes found for "$searchQuery"'
                  : 'No notes here! 🌸\nTap + to create a magical note.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Notes තිබෙන විට පෙන්වන Grid එක
    return MasonryGridView.count(
      padding: const EdgeInsets.all(10.0),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      addRepaintBoundaries: true,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return GestureDetector(
          onTap: () => onNoteTap(note),
          onLongPress: () => onNoteLongPress(note),
          child: NoteCard(note: note),
        );
      },
    );
  }
}
