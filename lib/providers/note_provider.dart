import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/notes_database.dart';
import '../models/note_model.dart';

enum SortOrder {
  dateAsc,
  dateDesc,
  titleAsc,
  titleDesc,
}

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _trashedNotes = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  SortOrder _sortOrder = SortOrder.dateDesc;

  // Folder List (Default Categories)
  List<String> _availableCategories = [
    'All',
    'Personal',
    'Work',
    'Ideas',
    'Wishlist'
  ];

  // Getters
  List<Note> get notes => _filterAndSortNotes();
  List<Note> get trashedNotes => _trashedNotes;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  SortOrder get sortOrder => _sortOrder;
  List<String> get availableCategories => _availableCategories;

  NoteProvider() {
    _loadCategories(); // Saved Folders Load කරනවා
    refreshAllData(); // Notes Load කරනවා
  }

  Future<void> refreshAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await NotesDatabase.instance.readAllNotes();
      _trashedNotes = await NotesDatabase.instance.readTrashedNotes();
    } catch (e) {
      debugPrint("Error loading notes: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Note Operations ---

  Future<void> addNote(Note note) async {
    await NotesDatabase.instance.create(note);
    await refreshAllData();
  }

  Future<void> updateNote(Note note) async {
    await NotesDatabase.instance.update(note);
    await refreshAllData();
  }

  Future<void> moveToTrash(Note note) async {
    final trashedNote = note.copy(isTrashed: true);
    await NotesDatabase.instance.update(trashedNote);
    await refreshAllData();
  }

  Future<void> restoreFromTrash(Note note) async {
    final restoredNote = note.copy(isTrashed: false);
    await NotesDatabase.instance.update(restoredNote);
    await refreshAllData();
  }

  Future<void> deletePermanently(int id) async {
    await NotesDatabase.instance.delete(id);
    await refreshAllData();
  }

  // ✅ App එකේ Lag එකක් නැතිව Trash එක පමණක් එකවර මකා දැමීම
  Future<void> emptyTrash() async {
    await NotesDatabase.instance.deleteTrashedNotes();
    await refreshAllData();
  }

  // 🔴 අවවාදයයි: App එකේ ඇති සියලුම දත්ත (Active + Trash) මකා දමයි!
  Future<void> deleteAllPermanently() async {
    await NotesDatabase.instance.deleteAllNotes();
    await refreshAllData();
  }

  Future<void> togglePinNote(Note note) async {
    final updatedNote = note.copy(isPinned: !note.isPinned);
    await NotesDatabase.instance.update(updatedNote);
    await refreshAllData();
  }

  // --- Folder / Category Operations ---

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  Future<void> addCategory(String category) async {
    if (!_availableCategories.contains(category)) {
      _availableCategories.add(category);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String category) async {
    if (category != 'All' && _availableCategories.contains(category)) {
      _availableCategories.remove(category);

      if (_selectedCategory == category) {
        _selectedCategory = 'All';
      }

      await _saveCategories();
      notifyListeners();
    }
  }

  // --- SharedPreferences Logic for Folders ---

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_categories', _availableCategories);
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = prefs.getStringList('custom_categories');

    if (savedCategories != null) {
      _availableCategories = savedCategories;
      if (!_availableCategories.contains('All')) {
        _availableCategories.insert(0, 'All');
      }
      notifyListeners();
    }
  }

  // --- Filtering & Sorting Logic ---

  List<Note> _filterAndSortNotes() {
    List<Note> filtered = List.from(_notes);

    // 1. Filter by Category
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((note) => note.category == _selectedCategory).toList();
    }

    // 2. Sort Logic
    switch (_sortOrder) {
      case SortOrder.dateAsc:
        filtered.sort((a, b) => a.createdTime.compareTo(b.createdTime));
        break;
      case SortOrder.dateDesc:
        filtered.sort((a, b) => b.createdTime.compareTo(a.createdTime));
        break;
      case SortOrder.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOrder.titleDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    // 3. Pinned notes always on top
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    return filtered;
  }
}
