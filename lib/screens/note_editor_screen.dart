import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<Color> availableColors;

  const NoteEditorScreen({super.key, this.note, required this.availableColors});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _selectedColor;
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedColor = widget.note?.color ?? 0xFFFFFFFF;
    _reminderDateTime = widget.note?.reminderDateTime;
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    final now = DateTime.now();

    if (widget.note == null) {
      // Create new note
      final newNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        color: _selectedColor,
        reminderDateTime: _reminderDateTime,
      );
      await DatabaseService.instance.createNote(newNote);

      if (_reminderDateTime != null &&
          _reminderDateTime!.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: newNote.id.hashCode,
          title: 'Reminder: ${title.isEmpty ? "Note" : title}',
          body: content.isEmpty ? 'You have a note reminder' : content,
          scheduledDate: _reminderDateTime!,
        );
      }
    } else {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        color: _selectedColor,
        reminderDateTime: _reminderDateTime,
      );
      await DatabaseService.instance.updateNote(updatedNote);

      // Update notification
      await NotificationService.instance.cancelNotification(
        widget.note!.id.hashCode,
      );
      if (_reminderDateTime != null &&
          _reminderDateTime!.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: updatedNote.id.hashCode,
          title: 'Reminder: ${title.isEmpty ? "Note" : title}',
          body: content.isEmpty ? 'You have a note reminder' : content,
          scheduledDate: _reminderDateTime!,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _selectedColor == 0xFFFFFFFF
        ? (isDark ? const Color(0xFF2E2D32) : Colors.white)
        : Color(_selectedColor);

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveNote();
            },
          ),
          actions: [
            if (_reminderDateTime != null)
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded, size: 22),
                onPressed: _removeReminder,
                tooltip: 'Remove reminder',
                color: const Color(0xFF2DBD6C),
              ),
            IconButton(
              icon: const Icon(Icons.alarm_add_rounded, size: 22),
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
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark ? Colors.grey.shade100 : Colors.black87,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark ? Colors.grey.shade200 : Colors.black87,
                      ),
                      maxLines: null,
                      autofocus: widget.note == null,
                    ),
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
    _contentController.dispose();
    super.dispose();
  }
}
