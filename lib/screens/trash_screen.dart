import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/file_storage_service.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Note> _deletedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
    _cleanupOldNotes();
  }

  Future<void> _loadDeletedNotes() async {
    setState(() => _isLoading = true);
    final notes = await DatabaseService.instance.getDeletedNotes();
    setState(() {
      _deletedNotes = notes;
      _isLoading = false;
    });
  }

  Future<void> _cleanupOldNotes() async {
    await DatabaseService.instance.deleteOldTrashNotes();
  }

  Future<void> _restoreNote(Note note) async {
    await DatabaseService.instance.restoreNote(note.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note restored')),
      );
      _loadDeletedNotes();
    }
  }

  Future<void> _permanentlyDeleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text(
          'This note will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.permanentlyDeleteNote(note.id);
      if (note.filePath != null) {
        await FileStorageService.instance.deleteNoteHtml(note.filePath!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note permanently deleted')),
        );
        _loadDeletedNotes();
      }
    }
  }

  Future<void> _emptyTrash() async {
    if (_deletedNotes.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: Text(
          'Permanently delete ${_deletedNotes.length} note(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final note in _deletedNotes) {
        await DatabaseService.instance.permanentlyDeleteNote(note.id);
        if (note.filePath != null) {
          await FileStorageService.instance.deleteNoteHtml(note.filePath!);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trash emptied')),
        );
        _loadDeletedNotes();
      }
    }
  }

  bool _isColorLight(int colorValue) {
    final color = Color(colorValue);
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  String _formatDeletedDate(DateTime? deletedAt) {
    if (deletedAt == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(deletedAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    }
    return 'Over 30 days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (_deletedNotes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Empty Trash',
              onPressed: _emptyTrash,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Trash is empty',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deleted notes are kept for 30 days',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _deletedNotes.length,
                  itemBuilder: (context, index) {
                    final note = _deletedNotes[index];
                    final isLight = _isColorLight(note.color);
                    
                    return Card(
                      color: Color(note.color),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: TextStyle(
                            color: isLight ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLight
                                      ? Colors.black54
                                      : Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Deleted ${_formatDeletedDate(note.deletedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isLight
                                    ? Colors.black45
                                    : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.restore,
                                color: isLight
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                              tooltip: 'Restore',
                              onPressed: () => _restoreNote(note),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_forever,
                                color: isLight ? Colors.red[700] : Colors.red[300],
                              ),
                              tooltip: 'Delete Permanently',
                              onPressed: () => _permanentlyDeleteNote(note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
