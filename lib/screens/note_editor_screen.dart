import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../database/notes_database.dart';
import '../providers/theme_provider.dart';

class ChecklistItem {
  TextEditingController controller;
  bool isChecked;
  FocusNode focusNode;

  ChecklistItem({
    required String text,
    this.isChecked = false,
  })  : controller = TextEditingController(text: text),
        focusNode = FocusNode();
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late FocusNode _editorFocusNode;

  late String _selectedCategory;

  // Default categories - Provider එකෙන් එන ඒවා එක්ක update වෙනවා
  List<String> _categories = ['Personal', 'Work', 'Ideas', 'Wishlist', 'All'];

  Note? _currentNote;
  Timer? _debounce;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<Color?> _lightColorAnimation;

  bool _isChecklist = false;
  List<ChecklistItem> _checklistItems = [];

  late Color _selectedNoteColor;
  final List<Color> _noteColorOptions = [
    const Color(0xfffffdd0), // Cream
    const Color(0xFFFADADD), // Pale Pink
    const Color(0xFFD4E4F7), // Pale Blue
    const Color(0xFFD9E8D4), // Pale Green
    const Color(0xFFF7E8D4), // Peach
    const Color(0xFFE8D4F7), // Lavender
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentNote = widget.note;
    _editorFocusNode = FocusNode();

    _selectedNoteColor = _currentNote?.color ?? const Color(0xfffffdd0);
    _titleController = TextEditingController(text: _currentNote?.title ?? '');

    // Category එක තෝරාගැනීම (default: Personal)
    _selectedCategory = _currentNote?.category ?? 'Personal';

    _isChecklist = _currentNote?.isChecklist ?? false;

    // Rich Text Editor එක Initialize කිරීම
    if (!_isChecklist &&
        _currentNote != null &&
        _currentNote!.content.isNotEmpty) {
      try {
        final contentJson = jsonDecode(_currentNote!.content);
        _quillController = QuillController(
          document: Document.fromJson(contentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // පරණ Plain text එකක් නම් එය Quill format එකට හරවනවා
        String content = _currentNote!.content;
        if (!content.endsWith('\n')) {
          content += '\n';
        }
        _quillController = QuillController(
          document: Document.fromDelta(Delta()..insert(content)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = QuillController.basic();
    }

    if (_isChecklist) {
      _parseChecklistContent();
    }

    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);

    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _updateColorAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider එකෙන් Categories ටික අරගන්නවා
    final noteProvider = Provider.of<NoteProvider>(context);
    setState(() {
      _categories = noteProvider.availableCategories;
      // දැනට තෝරාගෙන ඇති category එක list එකේ නැත්නම් default එකකට මාරු කරන්න
      if (!_categories.contains(_selectedCategory)) {
        if (_categories.contains('Personal')) {
          _selectedCategory = 'Personal';
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        } else {
          _selectedCategory = 'All'; // Fallback
        }
      }
    });
  }

  void _updateColorAnimation() {
    _lightColorAnimation = ColorTween(
      begin: _selectedNoteColor.withValues(alpha: 0.9),
      end: _selectedNoteColor,
    ).animate(_animationController);
  }

  void _parseChecklistContent() {
    if (_currentNote == null || _currentNote!.content.isEmpty) return;
    try {
      final List<dynamic> items = jsonDecode(_currentNote!.content);
      _checklistItems = items.map((item) {
        return ChecklistItem(
          text: item['text'] ?? '',
          isChecked: item['checked'] ?? false,
        );
      }).toList();
      for (var item in _checklistItems) {
        item.controller.addListener(_onTextChanged);
      }
    } catch (e) {
      _checklistItems = [ChecklistItem(text: _currentNote!.content)];
      _checklistItems.first.controller.addListener(_onTextChanged);
    }
  }

  String _serializeQuillContent() {
    return jsonEncode(_quillController.document.toDelta().toJson());
  }

  String _serializeChecklistContent() {
    final List<Map<String, dynamic>> items = _checklistItems.map((item) {
      return {
        'text': item.controller.text,
        'checked': item.isChecked,
      };
    }).toList();
    return jsonEncode(items);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _debounce?.cancel();

    for (var item in _checklistItems) {
      item.controller.dispose();
      item.focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveNote(isAutoSave: true, isClosing: true);
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _saveNote(isAutoSave: true);
    });
  }

  Future<void> _saveNote(
      {bool isAutoSave = false, bool isClosing = false}) async {
    if (_isSaving) return;
    if (mounted) setState(() => _isSaving = true);

    final title = _titleController.text;
    final String content;
    if (_isChecklist) {
      content = _serializeChecklistContent();
    } else {
      content = _serializeQuillContent();
    }

    // හිස් Note එකක් නම් Save කරන්න එපා
    if (title.isEmpty &&
        (content.isEmpty || content == '[{"insert":"\\n"}]') &&
        _checklistItems.isEmpty) {
      if (mounted) setState(() => _isSaving = false);
      if (!isAutoSave) Navigator.of(context).pop();
      return;
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    final noteToSave = Note(
      id: _currentNote?.id,
      title: title.isEmpty ? 'Untitled Note' : title,
      content: content,
      color: _selectedNoteColor,
      isChecklist: _isChecklist,
      isPinned: _currentNote?.isPinned ?? false,
      isTrashed: _currentNote?.isTrashed ?? false,
      category: _selectedCategory,
      createdTime: _currentNote?.createdTime ?? DateTime.now(),
    );

    if (_currentNote == null) {
      final newNote = await NotesDatabase.instance.create(noteToSave);
      if (mounted) setState(() => _currentNote = newNote);
    } else {
      await NotesDatabase.instance.update(noteToSave);
    }

    if (mounted) setState(() => _isSaving = false);

    if (!isAutoSave) {
      await noteProvider.refreshAllData();
      if (mounted) Navigator.of(context).pop();
    } else if (isClosing) {
      await noteProvider.refreshAllData();
    }
  }

  void _toggleChecklistMode() {
    setState(() {
      _isChecklist = !_isChecklist;
      if (_isChecklist) {
        _quillController.removeListener(_onTextChanged);
        final plainText = _quillController.document.toPlainText().trim();

        if (plainText.isNotEmpty) {
          _checklistItems = plainText.split('\n').map((line) {
            return ChecklistItem(text: line, isChecked: false);
          }).toList();
        } else {
          _checklistItems = [ChecklistItem(text: '')];
        }
        for (var item in _checklistItems) {
          item.controller.addListener(_onTextChanged);
        }
      } else {
        String plainText =
            _checklistItems.map((item) => item.controller.text).join('\n');

        if (!plainText.endsWith('\n')) {
          plainText += '\n';
        }

        final newDoc = Document.fromDelta(Delta()..insert(plainText));
        _quillController = QuillController(
            document: newDoc,
            selection: const TextSelection.collapsed(offset: 0));
        _quillController.addListener(_onTextChanged);

        for (var item in _checklistItems) {
          item.controller.dispose();
        }
        _checklistItems.clear();
      }
      _onTextChanged();
    });
  }

  void _addChecklistItem() {
    setState(() {
      final newItem = ChecklistItem(text: '');
      newItem.controller.addListener(_onTextChanged);
      _checklistItems.add(newItem);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          newItem.focusNode.requestFocus();
        }
      });
    });
    _onTextChanged();
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _noteColorOptions.map((color) {
              bool isSelected = _selectedNoteColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNoteColor = color;
                    _updateColorAnimation();
                  });
                  _onTextChanged();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: ThemeData.estimateBrightnessForColor(color) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ✅ වැදගත් Features: Bold, Italic, List, Header සහිත Toolbar එක
  Widget _buildQuillEditorWidget(Color textColor, Color hintColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillToolbar.simple(
              controller: _quillController,
              configurations: QuillSimpleToolbarConfigurations(
                showFontFamily: false,
                showFontSize: false,
                showSearchButton: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showLink: false,
                showCodeBlock: false,
                showIndent: true, // Indent තියෙනවා
                showListNumbers: true, // 1, 2, 3 List
                showListBullets: true, // Bullet Points
                showBoldButton: true, // Bold
                showItalicButton: true, // Italic
                showUnderLineButton: true, // Underline
                showStrikeThrough: true, // Strikethrough
                showQuote: true, // Quote
                showHeaderStyle: true, // H1, H2, H3

                // Toolbar එකේ පාටවල් හදනවා
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: QuillIconTheme(
                      iconButtonUnselectedData: IconButtonData(
                          color: textColor.withValues(alpha: 0.6)),
                      iconButtonSelectedData: IconButtonData(color: textColor),
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_editorFocusNode.hasFocus) {
                _editorFocusNode.requestFocus();
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                configurations: const QuillEditorConfigurations(
                  placeholder: 'Type your note here...',
                  autoFocus: true,
                  expands: true,
                  scrollable: true,
                  padding: EdgeInsets.zero,
                  sharedConfigurations: QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistEditor(Color textColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _checklistItems.length + 1,
            itemBuilder: (context, index) {
              if (index == _checklistItems.length) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 50),
                  child: TextButton.icon(
                    onPressed: _addChecklistItem,
                    icon: Icon(Icons.add,
                        color: textColor.withValues(alpha: 0.6)),
                    label: Text(
                      'Add Item',
                      style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                );
              }

              final item = _checklistItems[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Checkbox(
                      value: item.isChecked,
                      activeColor: Theme.of(context).primaryColor,
                      checkColor: Colors.white,
                      side: BorderSide(color: textColor.withValues(alpha: 0.5)),
                      onChanged: (value) {
                        setState(() {
                          item.isChecked = value ?? false;
                        });
                        _onTextChanged();
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: item.controller,
                      focusNode: item.focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isChecked
                            ? textColor.withValues(alpha: 0.5)
                            : textColor.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'List item',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (value) {
                        _addChecklistItem();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: textColor.withValues(alpha: 0.4), size: 20),
                    onPressed: () {
                      setState(() {
                        item.controller.dispose();
                        item.focusNode.dispose();
                        _checklistItems.removeAt(index);
                      });
                      _onTextChanged();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAppDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final animation = _lightColorAnimation;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final backgroundColor = animation.value ??
            (isAppDarkMode ? const Color(0xFF2D2D2D) : _selectedNoteColor);

        final isDarkBackground =
            ThemeData.estimateBrightnessForColor(backgroundColor) ==
                Brightness.dark;
        final textColor = isDarkBackground ? Colors.white : Colors.black;
        final hintColor =
            isDarkBackground ? Colors.grey.shade400 : Colors.black54;
        final statusBarIconBrightness =
            isDarkBackground ? Brightness.light : Brightness.dark;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: statusBarIconBrightness,
              statusBarBrightness:
                  isDarkBackground ? Brightness.dark : Brightness.light,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                  icon: Icon(Icons.undo, color: textColor),
                  onPressed: () {
                    if (!_isChecklist) _quillController.undo();
                  }),
              IconButton(
                  icon: Icon(Icons.redo, color: textColor),
                  onPressed: () {
                    if (!_isChecklist) _quillController.redo();
                  }),
              IconButton(
                icon: Icon(Icons.color_lens_outlined, color: textColor),
                onPressed: _showColorPicker,
              ),
              IconButton(
                icon: Icon(
                  _isChecklist ? Icons.notes_rounded : Icons.check_box_outlined,
                  color: textColor,
                ),
                onPressed: _toggleChecklistMode,
              ),
              IconButton(
                  icon: Icon(Icons.save_outlined, color: textColor),
                  onPressed: () => _saveNote()),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  // ✅ FIX: value -> initialValue ලෙස වෙනස් කරන ලදී
                  initialValue: _categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'Personal',
                  dropdownColor:
                      isAppDarkMode ? const Color(0xFF3C4043) : Colors.white,
                  style: TextStyle(color: textColor),
                  iconEnabledColor: textColor,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCategory = newValue);
                      _onTextChanged();
                    }
                  },
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.label_outline,
                          color: textColor.withValues(alpha: 0.7))),
                ),
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Title ✨',
                    hintStyle: TextStyle(color: hintColor),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                Expanded(
                  child: _isChecklist
                      ? _buildChecklistEditor(textColor)
                      : _buildQuillEditorWidget(textColor, hintColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
