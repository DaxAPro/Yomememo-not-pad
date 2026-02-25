import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import 'note_card_widget.dart'; // ෆයිල් එක import කරලා තියෙනවා

// Styles 3 අර්ථ දැක්වීම
enum NoteViewStyle { list, grid, staggered }

class NotesLayoutBuilder extends StatelessWidget {
  final List<Note> notes;
  final NoteViewStyle viewStyle;
  final String searchQuery;
  final bool isDarkMode;
  final Function(Note) onNoteTap;
  final Function(Note) onNoteLongPress;

  const NotesLayoutBuilder({
    super.key,
    required this.notes,
    required this.viewStyle,
    required this.searchQuery,
    required this.isDarkMode,
    required this.onNoteTap,
    required this.onNoteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(
        child: Text(
          'No notes found...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // 🌟 Style 1: List View (එක පේළියට එකයි)
    if (viewStyle == NoteViewStyle.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => onNoteTap(note),
              onLongPress: () => onNoteLongPress(note),
              // ✅ මෙතන නම NoteCard විදිහට හැදුවා
              child: NoteCard(note: note),
            ),
          );
        },
      );
    }

    // 🌟 Style 2: Grid View (කොටු හැඩයට 2ක් සමාන උසකින්)
    if (viewStyle == NoteViewStyle.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return GestureDetector(
            onTap: () => onNoteTap(note),
            onLongPress: () => onNoteLongPress(note),
            // ✅ මෙතන නම NoteCard විදිහට හැදුවා
            child: NoteCard(note: note),
          );
        },
      );
    }

    // 🌟 Style 3: Staggered View (උස වෙනස් වෙන Masonry Style)
    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return GestureDetector(
          onTap: () => onNoteTap(note),
          onLongPress: () => onNoteLongPress(note),
          // ✅ මෙතන නම NoteCard විදිහට හැදුවා
          child: NoteCard(note: note),
        );
      },
    );
  }
}
