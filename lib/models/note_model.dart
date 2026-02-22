import 'package:flutter/material.dart';

// ✅ FIX: final වෙනුවට const භාවිතා කිරීම
const String tableNotes = 'notes';

class NoteFields {
  static final List<String> values = [
    id,
    isPinned,
    isChecklist,
    isTrashed,
    title,
    content,
    category,
    color,
    createdTime
  ];

  static const String id = '_id';
  static const String isPinned = 'isPinned';
  static const String isChecklist = 'isChecklist';
  static const String isTrashed = 'isTrashed';
  static const String title = 'title';
  static const String content = 'content';
  static const String category = 'category';
  static const String color = 'color';
  static const String createdTime = 'createdTime';
}

class Note {
  final int? id;
  final bool isPinned;
  final bool isChecklist;
  final bool isTrashed;
  final String title;
  final String content;
  final String category;
  final Color color;
  final DateTime createdTime;

  const Note({
    this.id,
    required this.isPinned,
    required this.isChecklist,
    required this.isTrashed,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdTime,
  });

  Note copy({
    int? id,
    bool? isPinned,
    bool? isChecklist,
    bool? isTrashed,
    String? title,
    String? content,
    String? category,
    Color? color,
    DateTime? createdTime,
  }) =>
      Note(
        id: id ?? this.id,
        isPinned: isPinned ?? this.isPinned,
        isChecklist: isChecklist ?? this.isChecklist,
        isTrashed: isTrashed ?? this.isTrashed,
        title: title ?? this.title,
        content: content ?? this.content,
        category: category ?? this.category,
        color: color ?? this.color,
        createdTime: createdTime ?? this.createdTime,
      );

  static Note fromJson(Map<String, Object?> json) => Note(
        id: json[NoteFields.id] as int?,
        isPinned: json[NoteFields.isPinned] == 1,
        isChecklist: json[NoteFields.isChecklist] == 1,
        isTrashed: json[NoteFields.isTrashed] == 1,
        title: json[NoteFields.title] as String,
        content: json[NoteFields.content] as String,
        category: json[NoteFields.category] as String,
        color: Color(json[NoteFields.color] as int),
        createdTime: DateTime.parse(json[NoteFields.createdTime] as String),
      );

  Map<String, Object?> toJson() => {
        NoteFields.id: id,
        NoteFields.isPinned: isPinned ? 1 : 0,
        NoteFields.isChecklist: isChecklist ? 1 : 0,
        NoteFields.isTrashed: isTrashed ? 1 : 0,
        NoteFields.title: title,
        NoteFields.content: content,
        NoteFields.category: category,

        // ✅ FIX: .value වෙනුවට .toARGB32() භාවිතා කිරීම
        NoteFields.color: color.toARGB32(),

        NoteFields.createdTime: createdTime.toIso8601String(),
      };
}
