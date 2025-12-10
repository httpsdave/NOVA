import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/attachment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/file_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../models/note_template.dart';
import 'notebooks_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<Color> availableColors;
  final NoteTemplate? initialTemplate;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.availableColors,
    this.initialTemplate,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _descriptionController;
  late int _selectedColor;
  DateTime? _reminderDateTime;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  List<Note> _relatedNotes = [];
  Notebook? _selectedNotebook;
  List<Notebook> _notebooks = [];
  List<Attachment> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    
    // Initialize with template if provided
    if (widget.initialTemplate != null && widget.note == null) {
      _titleController = TextEditingController(text: widget.initialTemplate!.name);
      _contentController = TextEditingController(text: widget.initialTemplate!.content);
      _descriptionController = TextEditingController(text: widget.initialTemplate!.description);
      _selectedColor = widget.initialTemplate!.color;
      _tags.addAll(widget.initialTemplate!.tags);
    } else {
      _titleController = TextEditingController(text: widget.note?.title ?? '');
      _descriptionController = TextEditingController(text: widget.note?.description ?? '');
      _contentController = TextEditingController(
        text: widget.note?.content ?? '',
      );
      _selectedColor = widget.note?.color ?? 0xFFFFFFFF;
      _reminderDateTime = widget.note?.reminderDateTime;
      
      if (widget.note?.tags != null) {
        _tags.addAll(widget.note!.tags);
      }
    }
    
    if (widget.note != null && widget.note!.tags.isNotEmpty) {
      _loadRelatedNotes();
    }
    
    _loadNotebooks();
    _loadSelectedNotebook();
    if (widget.note != null) {
      _loadAttachments();
    }
  }

  Future<void> _loadAttachments() async {
    if (widget.note == null) return;
    final attachments = await DatabaseService.instance.getAttachmentsByNote(widget.note!.id);
    setState(() {
      _attachments = attachments;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(path.join(appDir.path, 'nova_attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final String fileName = '${const Uuid().v4()}${path.extension(image.path)}';
      final String newPath = path.join(attachmentsDir.path, fileName);
      final File imageFile = File(image.path);
      await imageFile.copy(newPath);

      // Get file size
      final fileSize = await imageFile.length();

      // Create attachment record (will be saved when note is saved)
      final attachment = Attachment(
        id: const Uuid().v4(),
        noteId: widget.note?.id ?? 'temp', // Will be updated when note is saved
        filePath: newPath,
        fileName: path.basename(image.path),
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
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _removeAttachment(Attachment attachment) async {
    setState(() {
      _attachments.remove(attachment);
    });

    // Delete file and database record if note already exists
    if (widget.note != null) {
      try {
        final file = File(attachment.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await DatabaseService.instance.deleteAttachment(attachment.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing attachment: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadNotebooks() async {
    final notebooks = await DatabaseService.instance.getAllNotebooks();
    setState(() {
      _notebooks = notebooks;
    });
  }

  Future<void> _loadSelectedNotebook() async {
    if (widget.note?.notebookId != null) {
      final notebook = await DatabaseService.instance.getNotebook(widget.note!.notebookId!);
      setState(() {
        _selectedNotebook = notebook;
      });
    }
  }

  Future<void> _selectNotebook() async {
    final result = await Navigator.push<Notebook>(
      context,
      MaterialPageRoute(
        builder: (context) => const NotebooksScreen(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedNotebook = result;
      });
    }
  }

  Future<void> _loadRelatedNotes() async {
    if (widget.note == null) return;
    final related = await DatabaseService.instance.getRelatedNotes(widget.note!);
    if (mounted) {
      setState(() => _relatedNotes = related);
    }
  }

  Future<void> _saveNote() async {
    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final description = _descriptionController.text.trim();

      if (title.isEmpty && content.isEmpty) {
        Navigator.pop(context, false);
        return;
      }

      final now = DateTime.now();
      final htmlContent = '<p>${content.replaceAll('\n', '</p><p>')}</p>';

    if (widget.note == null) {
      // Create new note
      final newNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        htmlContent: htmlContent,
        description: description,
        tags: _tags,
        createdAt: now,
        updatedAt: now,
        color: _selectedColor,
        reminderDateTime: _reminderDateTime,
        notebookId: _selectedNotebook?.id,
      );
      await DatabaseService.instance.createNote(newNote);
      _currentNote = newNote; // Store for PDF export
      
      // Save attachments
      for (final attachment in _attachments) {
        final attachmentWithNoteId = attachment.copyWith(noteId: newNote.id);
        await DatabaseService.instance.createAttachment(attachmentWithNoteId);
      }
      
      // Save as HTML file
      final filePath = await FileStorageService.instance.saveNoteAsHtml(newNote);
      final noteWithPath = newNote.copyWith(filePath: filePath);
      await DatabaseService.instance.updateNote(noteWithPath);
      _currentNote = noteWithPath; // Update with file path

      if (_reminderDateTime != null &&
          _reminderDateTime!.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: newNote.id.hashCode,
          title: 'Reminder: ${title.isEmpty ? "Note" : title}',
          body: description.isEmpty ? content : description,
          scheduledDate: _reminderDateTime!,
        );
      }
    } else {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        htmlContent: htmlContent,
        description: description,
        tags: _tags,
        updatedAt: now,
        color: _selectedColor,
        reminderDateTime: _reminderDateTime,
        notebookId: _selectedNotebook?.id,
      );
      await DatabaseService.instance.updateNote(updatedNote);
      _currentNote = updatedNote; // Store for PDF export
      
      // Save any new attachments
      for (final attachment in _attachments) {
        if (attachment.noteId == 'temp') {
          final attachmentWithNoteId = attachment.copyWith(noteId: updatedNote.id);
          await DatabaseService.instance.createAttachment(attachmentWithNoteId);
        }
      }
      
      // Update HTML file
      await FileStorageService.instance.saveNoteAsHtml(updatedNote);

      // Update notification
      await NotificationService.instance.cancelNotification(
        widget.note!.id.hashCode,
      );
      if (_reminderDateTime != null &&
          _reminderDateTime!.isAfter(DateTime.now())) {
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

  Future<void> _selectReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _reminderDateTime ?? DateTime.now().add(const Duration(days: 1)),
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
      _reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _removeReminder() {
    setState(() {
      _reminderDateTime = null;
    });
  }

  Future<void> _exportToPdf() async {
    await _saveNote();
    if (_currentNote == null) return;

    try {
      final file = await PdfExportService.instance.exportNoteToPdf(_currentNote!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported to ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
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

  Future<void> _sharePdf() async {
    await _saveNote();
    if (_currentNote == null) return;

    try {
      await PdfExportService.instance.sharePdf(_currentNote!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    }
  }

  Future<void> _printNote() async {
    await _saveNote();
    if (_currentNote == null) return;

    try {
      await PdfExportService.instance.printPdf(_currentNote!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _loadRelatedNotes();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _loadRelatedNotes();
  }

  bool _isColorLight(int colorValue) {
    final color = Color(colorValue);
    // Calculate luminance - if white (0xFFFFFFFF), check theme
    if (colorValue == 0xFFFFFFFF) {
      return Theme.of(context).brightness == Brightness.light;
    }
    // Calculate relative luminance
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  Widget _buildRelatedNoteCard(Note note, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () async {
          await _saveNote();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(
                  note: note,
                  availableColors: widget.availableColors,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade100 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DBD6C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2DBD6C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _selectedColor == 0xFFFFFFFF
        ? (isDark ? const Color(0xFF2E2D32) : Colors.white)
        : Color(_selectedColor);
    
    // Determine if the current background is dark
    final backgroundIsLight = _isColorLight(_selectedColor);
    final textColor = backgroundIsLight ? Colors.black87 : Colors.white;
    final hintColor = backgroundIsLight ? Colors.grey.shade500 : Colors.grey.shade400;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          iconTheme: IconThemeData(color: textColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveNote();
            },
          ),
          actions: [
            // Export menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 22, color: textColor),
              tooltip: 'More options',
              onSelected: (value) async {
                switch (value) {
                  case 'export_pdf':
                    await _exportToPdf();
                    break;
                  case 'share_pdf':
                    await _sharePdf();
                    break;
                  case 'print':
                    await _printNote();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 20),
                      SizedBox(width: 12),
                      Text('Export to PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 12),
                      Text('Share as PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 12),
                      Text('Print Note'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.attach_file_rounded, size: 22, color: textColor),
              onPressed: _pickImage,
              tooltip: 'Attach image',
            ),
            if (_reminderDateTime != null)
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded, size: 22),
                onPressed: _removeReminder,
                tooltip: 'Remove reminder',
                color: const Color(0xFF2DBD6C),
              ),
            IconButton(
              icon: Icon(Icons.alarm_add_rounded, size: 22, color: textColor),
              onPressed: _selectReminderDateTime,
              tooltip: 'Set reminder',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Color selector
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.availableColors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = widget.availableColors[index];
                  final colorInt = color.value;
                  final displayColor = colorInt == 0xFFFFFFFF
                      ? (isDark ? const Color(0xFF2E2D32) : Colors.white)
                      : color;
                  final isSelected = _selectedColor == colorInt;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorInt;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2DBD6C)
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2DBD6C).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: colorInt == 0xFFFFFFFF
                                  ? const Color(0xFF2DBD6C)
                                  : Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            // Notebook selector
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: _selectNotebook,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedNotebook?.name ?? 'No Notebook',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedNotebook != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _selectedNotebook = null);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Reminder info
            if (_reminderDateTime != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBD6C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2DBD6C).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alarm_rounded,
                      color: Color(0xFF2DBD6C),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, y - HH:mm').format(_reminderDateTime!),
                        style: const TextStyle(
                          color: Color(0xFF2DBD6C),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF2DBD6C)),
                      onPressed: _removeReminder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            // Note content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: textColor,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Add a short description...',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: textColor.withOpacity(0.8),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Tags Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: 'Add tags (e.g., work, personal)...',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: backgroundIsLight 
                                  ? Colors.white.withOpacity(0.8) 
                                  : Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: backgroundIsLight ? Colors.grey.shade300 : Colors.grey.shade600),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: backgroundIsLight ? Colors.grey.shade300 : Colors.grey.shade600),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2DBD6C), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add, color: Color(0xFF2DBD6C)),
                                onPressed: _addTag,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            backgroundColor: const Color(0xFF2DBD6C),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                            onDeleted: () => _removeTag(tag),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: textColor,
                      ),
                      maxLines: null,
                      autofocus: widget.note == null,
                    ),
                    // Attachments Section
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments.map((attachment) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(attachment.filePath),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeAttachment(attachment),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    // Related Notes Section
                    if (_relatedNotes.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Related Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade100 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._relatedNotes.map((note) => _buildRelatedNoteCard(note, isDark)),
                    ],
                  ],
                ),
              ),
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
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
