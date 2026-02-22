import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  const NoteCard({super.key, required this.note});

  // ✅ Quill Data සාමාන්‍ය Text එකක් බවට පත්කිරීම (No Lag)
  String _getPlainText() {
    if (note.content.isEmpty) return "Empty Note";
    try {
      final contentJson = jsonDecode(note.content);
      final doc = Document.fromJson(contentJson);
      return doc.toPlainText().trim();
    } catch (e) {
      return note.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = note.color;
    final time = DateFormat('MMM d, yyyy').format(note.createdTime);
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          // ✅ Frosted Glass Effect එක
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4), // 40% විනිවිද බව
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5), // Glass Border
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.push_pin,
                            size: 18, color: textColor.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Content පෙන්වීම
                note.isChecklist
                    ? _buildChecklistPreview(textColor)
                    : Text(
                        _getPlainText(),
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 14),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.category,
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(time,
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(Color textColor) {
    List<Map<String, dynamic>> items = [];
    try {
      if (note.content.isNotEmpty) {
        items = (jsonDecode(note.content) as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      return Text(note.content,
          style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis);
    }

    // ✅ FIX: if statement එක curly braces { } ඇතුළත ලිවීම
    if (items.isEmpty) {
      return Text(
        'Empty Checklist',
        style: TextStyle(color: textColor.withValues(alpha: 0.5)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.take(3).map((item) {
        final bool isChecked = item['checked'] ?? false;
        final String text = item['text'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 14, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
