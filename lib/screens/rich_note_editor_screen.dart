import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/attachment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/file_storage_service.dart';
import 'notebooks_screen.dart';

class RichNoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? templateType; // For templates
  final List<Color> availableColors;

  const RichNoteEditorScreen({
    super.key,
    this.note,
    this.templateType,
    required this.availableColors,
  });

  @override
  State<RichNoteEditorScreen> createState() => _RichNoteEditorScreenState();
}

class _RichNoteEditorScreenState extends State<RichNoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  late int _selectedColor;
  DateTime? _reminderDateTime;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  Notebook? _selectedNotebook;
  List<Attachment> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(text: widget.note?.description ?? '');
    _selectedColor = widget.note?.color ?? 0xFFFFFFFF;
    _reminderDateTime = widget.note?.reminderDateTime;
    
    if (widget.note?.tags != null) {
      _tags.addAll(widget.note!.tags);
    }
    
    _initializeQuillController();
    
    _loadSelectedNotebook();
    if (widget.note != null) {
      _loadAttachments();
    }
  }

  void _initializeQuillController() {
    try {
      // Initialize with existing content or template
      if (widget.note != null && widget.note!.htmlContent.isNotEmpty) {
        // Try to parse existing Quill delta JSON
        try {
          final delta = quill.Document.fromJson(jsonDecode(widget.note!.htmlContent));
          _quillController = quill.QuillController(
            document: delta,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          // If parsing fails, use plain text content
          _quillController = quill.QuillController.basic();
          if (widget.note!.content.isNotEmpty) {
            _quillController.document.insert(0, widget.note!.content);
          }
        }
      } else if (widget.templateType != null) {
        _quillController = quill.QuillController.basic();
        _applyTemplate(widget.templateType!);
      } else {
        _quillController = quill.QuillController.basic();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _quillController = quill.QuillController.basic();
      setState(() => _isLoading = false);
    }
  }

  void _applyTemplate(String templateType) {
    final delta = _quillController.document;
    
    switch (templateType) {
      case 'meeting':
        delta.insert(0, 'Meeting Notes\n');
        _quillController.formatText(0, 13, quill.Attribute.h1);
        delta.insert(14, '\nDate: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}\n');
        delta.insert(delta.length, '\nAttendees:\n• \n\nAgenda:\n• \n\nNotes:\n\n\nAction Items:\n• ');
        _titleController.text = 'Meeting - ${DateFormat('MMM dd').format(DateTime.now())}';
        break;
        
      case 'todo':
        delta.insert(0, 'To-Do List\n');
        _quillController.formatText(0, 10, quill.Attribute.h1);
        delta.insert(11, '\n☐ \n☐ \n☐ ');
        _titleController.text = 'To-Do - ${DateFormat('MMM dd').format(DateTime.now())}';
        break;
        
      case 'journal':
        delta.insert(0, '${DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now())}\n');
        _quillController.formatText(0, delta.length - 1, quill.Attribute.h2);
        delta.insert(delta.length, '\n\nHow I\'m feeling:\n\n\nToday\'s highlights:\n• \n\nThoughts:\n\n');
        _titleController.text = 'Journal - ${DateFormat('MMM dd').format(DateTime.now())}';
        break;
        
      case 'recipe':
        delta.insert(0, 'Recipe Name\n');
        _quillController.formatText(0, 11, quill.Attribute.h1);
        delta.insert(12, '\nPrep Time: \nCook Time: \nServings: \n\nIngredients:\n• \n\nInstructions:\n1. ');
        _titleController.text = 'Recipe';
        break;
    }
  }

  Future<void> _loadAttachments() async {
    if (widget.note == null) return;
    final attachments = await DatabaseService.instance.getAttachmentsByNote(widget.note!.id);
    setState(() {
      _attachments = attachments;
    });
  }

  Future<void> _loadSelectedNotebook() async {
    if (widget.note?.notebookId != null) {
      final notebook = await DatabaseService.instance.getNotebook(widget.note!.notebookId!);
      setState(() => _selectedNotebook = notebook);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(path.join(appDir.path, 'nova_attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final String fileName = '${const Uuid().v4()}${path.extension(image.path)}';
      final String newPath = path.join(attachmentsDir.path, fileName);
      final File imageFile = File(image.path);
      await imageFile.copy(newPath);

      final fileSize = await imageFile.length();

      final attachment = Attachment(
        id: const Uuid().v4(),
        noteId: widget.note?.id ?? '',
        filePath: newPath,
        fileName: fileName,
        fileType: 'image',
        fileSize: fileSize,
        createdAt: DateTime.now(),
      );

      setState(() {
        _attachments.add(attachment);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding image: $e')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // Get plain text content
      final content = _quillController.document.toPlainText();
      
      // Get delta JSON for rich text storage
      final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
      
      // Generate HTML for file storage
      final htmlContent = _generateHtml(title, content);

      if (title.isEmpty && content.isEmpty) {
        if (mounted) {
          Navigator.pop(context, false);
        }
        return;
      }

      final now = DateTime.now();

      if (widget.note == null) {
        final newNote = Note(
          id: const Uuid().v4(),
          title: title,
          content: content,
          htmlContent: deltaJson, // Store Quill delta JSON
          description: description,
          tags: _tags,
          createdAt: now,
          updatedAt: now,
          color: _selectedColor,
          reminderDateTime: _reminderDateTime,
          notebookId: _selectedNotebook?.id,
        );
        await DatabaseService.instance.createNote(newNote);
        
        for (final attachment in _attachments) {
          final attachmentWithNoteId = attachment.copyWith(noteId: newNote.id);
          await DatabaseService.instance.createAttachment(attachmentWithNoteId);
        }
        
        final filePath = await FileStorageService.instance.saveNoteAsHtml(newNote.copyWith(htmlContent: htmlContent));
        final noteWithPath = newNote.copyWith(filePath: filePath);
        await DatabaseService.instance.updateNote(noteWithPath);

        if (_reminderDateTime != null && _reminderDateTime!.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleNotification(
            id: newNote.id.hashCode,
            title: 'Reminder: ${title.isEmpty ? "Note" : title}',
            body: description.isEmpty ? content : description,
            scheduledDate: _reminderDateTime!,
          );
        }
      } else {
        final updatedNote = widget.note!.copyWith(
          title: title,
          content: content,
          htmlContent: deltaJson,
          description: description,
          tags: _tags,
          updatedAt: now,
          color: _selectedColor,
          reminderDateTime: _reminderDateTime,
          notebookId: _selectedNotebook?.id,
        );
        await DatabaseService.instance.updateNote(updatedNote);
        
        await FileStorageService.instance.saveNoteAsHtml(updatedNote.copyWith(htmlContent: htmlContent));

        await NotificationService.instance.cancelNotification(widget.note!.id.hashCode);
        if (_reminderDateTime != null && _reminderDateTime!.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleNotification(
            id: updatedNote.id.hashCode,
            title: 'Reminder: ${title.isEmpty ? "Note" : title}',
            body: description.isEmpty ? content : description,
            scheduledDate: _reminderDateTime!,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
        Navigator.pop(context, false);
      }
    }
  }

  String _generateHtml(String title, String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$title</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
        h1 { color: #2DBD6C; }
    </style>
</head>
<body>
    <h1>$title</h1>
    <p>${content.replaceAll('\n', '</p><p>')}</p>
</body>
</html>
''';
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();
      final title = _titleController.text.trim();
      final content = _quillController.document.toPlainText();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title.isEmpty ? 'Untitled Note' : title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2DBD6C'),
                  ),
                ),
                pw.SizedBox(height: 20),
                if (_descriptionController.text.isNotEmpty) ...[
                  pw.Text(
                    _descriptionController.text,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
                pw.Text(
                  'Created: ${DateFormat('MMM dd, yyyy h:mm a').format(widget.note?.createdAt ?? DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 20),
                pw.Text(content, style: const pw.TextStyle(fontSize: 12)),
                if (_tags.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Wrap(
                    spacing: 5,
                    children: _tags.map((tag) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E0F2E9'),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text('#$tag', style: const pw.TextStyle(fontSize: 10)),
                    )).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareNote() async {
    try {
      final title = _titleController.text.trim();
      final content = _quillController.document.toPlainText();
      
      final shareText = '''$title

${_descriptionController.text.isNotEmpty ? '${_descriptionController.text}\n\n' : ''}$content${_tags.isNotEmpty ? '\n\nTags: ${_tags.map((t) => '#$t').join(' ')}' : ''}''';

      await Share.share(
        shareText,
        subject: title.isEmpty ? 'Nova Note' : title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing note: $e')),
        );
      }
    }
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Meeting Notes'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('meeting');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('To-Do List'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('todo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Journal Entry'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('journal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Recipe'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('recipe');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Templates',
            onPressed: _showTemplateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportToPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // Title and metadata section
          Container(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          // Quill toolbar
          Container(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolbarButton(Icons.format_bold, () {
                    final isBold = _quillController.getSelectionStyle().attributes[quill.Attribute.bold.key] != null;
                    _quillController.formatSelection(isBold ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold);
                  }),
                  _buildToolbarButton(Icons.format_italic, () {
                    final isItalic = _quillController.getSelectionStyle().attributes[quill.Attribute.italic.key] != null;
                    _quillController.formatSelection(isItalic ? quill.Attribute.clone(quill.Attribute.italic, null) : quill.Attribute.italic);
                  }),
                  _buildToolbarButton(Icons.format_underline, () {
                    final isUnderline = _quillController.getSelectionStyle().attributes[quill.Attribute.underline.key] != null;
                    _quillController.formatSelection(isUnderline ? quill.Attribute.clone(quill.Attribute.underline, null) : quill.Attribute.underline);
                  }),
                  _buildToolbarButton(Icons.format_strikethrough, () {
                    final isStrike = _quillController.getSelectionStyle().attributes[quill.Attribute.strikeThrough.key] != null;
                    _quillController.formatSelection(isStrike ? quill.Attribute.clone(quill.Attribute.strikeThrough, null) : quill.Attribute.strikeThrough);
                  }),
                  const VerticalDivider(),
                  _buildToolbarButton(Icons.format_list_bulleted, () {
                    final isList = _quillController.getSelectionStyle().attributes[quill.Attribute.ul.key] != null;
                    _quillController.formatSelection(isList ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul);
                  }),
                  _buildToolbarButton(Icons.format_list_numbered, () {
                    final isList = _quillController.getSelectionStyle().attributes[quill.Attribute.ol.key] != null;
                    _quillController.formatSelection(isList ? quill.Attribute.clone(quill.Attribute.ol, null) : quill.Attribute.ol);
                  }),
                  _buildToolbarButton(Icons.checklist, () {
                    final isList = _quillController.getSelectionStyle().attributes[quill.Attribute.unchecked.key] != null;
                    _quillController.formatSelection(isList ? quill.Attribute.clone(quill.Attribute.unchecked, null) : quill.Attribute.unchecked);
                  }),
                  const VerticalDivider(),
                  _buildToolbarButton(Icons.format_quote, () {
                    final isQuote = _quillController.getSelectionStyle().attributes[quill.Attribute.blockQuote.key] != null;
                    _quillController.formatSelection(isQuote ? quill.Attribute.clone(quill.Attribute.blockQuote, null) : quill.Attribute.blockQuote);
                  }),
                  _buildToolbarButton(Icons.code, () {
                    final isCode = _quillController.getSelectionStyle().attributes[quill.Attribute.codeBlock.key] != null;
                    _quillController.formatSelection(isCode ? quill.Attribute.clone(quill.Attribute.codeBlock, null) : quill.Attribute.codeBlock);
                  }),
                  const VerticalDivider(),
                  _buildToolbarButton(Icons.format_clear, () {
                    _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.bold, null));
                    _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.italic, null));
                    _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.underline, null));
                  }),
                ],
              ),
            ),
          ),
          
          // Rich text editor
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              padding: const EdgeInsets.all(16),
              child: quill.QuillEditor(
                controller: _quillController,
                focusNode: _editorFocusNode,
                scrollController: ScrollController(),
              ),
            ),
          ),
          
          // Bottom metadata bar
          Container(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_reminderDateTime != null)
                    Chip(
                      avatar: const Icon(Icons.alarm, size: 18),
                      label: Text(
                        DateFormat('MMM dd, h:mm a').format(_reminderDateTime!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => setState(() => _reminderDateTime = null),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_reminderDateTime != null) const SizedBox(width: 8),
                  if (_selectedNotebook != null)
                    Chip(
                      avatar: Icon(Icons.folder, size: 18, color: Color(_selectedNotebook!.color)),
                      label: Text(_selectedNotebook!.name, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setState(() => _selectedNotebook = null),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_selectedNotebook != null) const SizedBox(width: 8),
                  ..._tags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      )),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _showOptionsMenu(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Set Reminder'),
            onTap: () {
              Navigator.pop(context);
              _selectReminderDateTime();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Add to Notebook'),
            onTap: () {
              Navigator.pop(context);
              _selectNotebook();
            },
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Add Tag'),
            onTap: () {
              Navigator.pop(context);
              _showAddTagDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Change Color'),
            onTap: () {
              Navigator.pop(context);
              _showColorPicker();
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Add Image'),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _reminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    if (time == null || !mounted) return;

    setState(() {
      _reminderDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _selectNotebook() async {
    final result = await Navigator.push<Notebook>(
      context,
      MaterialPageRoute(
        builder: (context) => const NotebooksScreen(),
      ),
    );

    if (result != null) {
      setState(() => _selectedNotebook = result);
    }
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            prefixText: '#',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
              setState(() => _tags.add(value.trim()));
              _tagController.clear();
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
                _tagController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.availableColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color.value);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color.value
                        ? const Color(0xFF2DBD6C)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
