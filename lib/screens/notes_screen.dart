import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';
import 'notebooks_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  List<Notebook> _notebooks = [];
  Notebook? _selectedNotebook;
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _noteColors = [
    Colors.white,
    const Color(0xFFFFF4E6),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5),
    const Color(0xFFFCE4EC),
    const Color(0xFFFFF9C4),
    const Color(0xFFE0F2F1),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadNotebooks();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = _selectedNotebook == null
          ? await DatabaseService.instance.getAllNotes()
          : await DatabaseService.instance.getNotesByNotebook(_selectedNotebook!.id);
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notes: $e')),
        );
      }
    }
  }

  Future<void> _loadNotebooks() async {
    try {
      final notebooks = await DatabaseService.instance.getAllNotebooks();
      setState(() {
        _notebooks = notebooks;
      });
    } catch (e) {
      // Silently fail for notebooks as it's not critical for main view
      print('Error loading notebooks: $e');
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
      _loadNotes();
    }
  }

  void _searchNotes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _notes;
      });
      return;
    }

    setState(() {
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteNote(Note note) async {
    await DatabaseService.instance.deleteNote(note.id);
    if (note.reminderDateTime != null) {
      await NotificationService.instance.cancelNotification(note.id.hashCode);
    }
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted')));
    }
  }

  Future<void> _togglePin(Note note) async {
    final updatedNote = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await DatabaseService.instance.updateNote(updatedNote);
    _loadNotes();
  }

  Color _getNoteColor(int colorValue, bool isDark) {
    if (colorValue == 0xFFFFFFFF) {
      return isDark ? const Color(0xFF2E2D32) : Colors.white;
    }
    return Color(colorValue);
  }

  bool _isCardColorLight(int colorValue, bool isDark) {
    // If it's the default white color, check the theme
    if (colorValue == 0xFFFFFFFF) {
      return !isDark;
    }
    // Calculate luminance for colored cards
    final color = Color(colorValue);
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _searchNotes,
              )
            : Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: const Color(0xFF2DBD6C),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nova',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredNotes = _notes;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2DBD6C),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Note Taking App',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('All Notes'),
              selected: _selectedNotebook == null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedNotebook = null);
                _loadNotes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Notebooks'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _selectNotebook();
              },
            ),
            if (_selectedNotebook != null)
              ListTile(
                leading: const SizedBox(width: 24),
                title: Text(_selectedNotebook!.name),
                selected: true,
                dense: true,
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _selectedNotebook = null);
                    _loadNotes();
                  },
                ),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrashScreen(),
                  ),
                ).then((_) => _loadNotes()); // Reload notes when returning
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
              onTap: () {
                themeProvider.toggleTheme();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 80,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSearching ? 'No notes found' : 'Create your first note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isSearching)
                    Text(
                      'Capture your thoughts and ideas',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    return _buildNoteCard(note, isDark);
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NoteEditorScreen(availableColors: _noteColors),
            ),
          );
          if (result == true) {
            _loadNotes();
          }
        },
        tooltip: 'New Note',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark) {
    final cardColor = _getNoteColor(note.color, isDark);
    final cardIsLight = _isCardColorLight(note.color, isDark);
    final textColor = cardIsLight ? Colors.black87 : Colors.white;
    final secondaryTextColor = cardIsLight ? Colors.grey.shade700 : Colors.grey.shade300;
    
    return Card(
      color: cardColor,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NoteEditorScreen(note: note, availableColors: _noteColors),
            ),
          );
          if (result == true) {
            _loadNotes();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: const Color(0xFF2DBD6C),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (note.reminderDateTime != null) ...[
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 12,
                      color: const Color(0xFF2DBD6C),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, y').format(note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cardIsLight ? Colors.grey.shade500 : Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: secondaryTextColor,
                    ),
                    onSelected: (value) {
                      if (value == 'pin') {
                        _togglePin(note);
                      } else if (value == 'delete') {
                        _showDeleteDialog(note);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(note.isPinned ? 'Unpin' : 'Pin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Custom masonry grid view implementation
class MasonryGridView extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const MasonryGridView({
    super.key,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.itemCount,
    required this.itemBuilder,
  });

  static MasonryGridView count({
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return MasonryGridView(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
