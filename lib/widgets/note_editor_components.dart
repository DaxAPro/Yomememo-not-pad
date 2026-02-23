import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ✅ Checklist Item Model එක
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

// ✅ 1. Quill Editor Widget (Rich Text)
class QuillEditorWidget extends StatelessWidget {
  final QuillController quillController;
  final FocusNode editorFocusNode;
  final Color textColor;

  const QuillEditorWidget({
    super.key,
    required this.quillController,
    required this.editorFocusNode,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillToolbar.simple(
              // ✅ FIX: controller එක configurations එකෙන් එළියට ගෙන ඇත
              controller: quillController,
              configurations: QuillSimpleToolbarConfigurations(
                showFontFamily: false,
                showFontSize: false,
                showSearchButton: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showLink: false,
                showCodeBlock: false,
                showIndent: true,
                showListNumbers: true,
                showListBullets: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showQuote: true,
                showHeaderStyle: true,
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
              if (!editorFocusNode.hasFocus) {
                editorFocusNode.requestFocus();
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              child: QuillEditor.basic(
                // ✅ FIX: controller එක configurations එකෙන් එළියට ගෙන ඇත
                controller: quillController,
                focusNode: editorFocusNode,
                configurations: const QuillEditorConfigurations(
                  placeholder: 'Type your note here...',
                  autoFocus: false,
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
}

// ✅ 2. Checklist Editor Widget
class ChecklistEditorWidget extends StatelessWidget {
  final List<ChecklistItem> checklistItems;
  final Color textColor;
  final VoidCallback onAddChecklistItem;
  final Function(int) onRemoveChecklistItem;
  final VoidCallback onTextChanged;

  const ChecklistEditorWidget({
    super.key,
    required this.checklistItems,
    required this.textColor,
    required this.onAddChecklistItem,
    required this.onRemoveChecklistItem,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: checklistItems.length + 1,
            itemBuilder: (context, index) {
              if (index == checklistItems.length) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 50),
                  child: TextButton.icon(
                    onPressed: onAddChecklistItem,
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

              final item = checklistItems[index];
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
                        item.isChecked = value ?? false;
                        onTextChanged(); // State update
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
                      onSubmitted: (_) => onAddChecklistItem(),
                      onChanged: (_) => onTextChanged(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: textColor.withValues(alpha: 0.4), size: 20),
                    onPressed: () => onRemoveChecklistItem(index),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
