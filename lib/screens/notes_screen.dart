import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/sort_option.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import 'rich_note_editor_screen.dart';
import 'trash_screen.dart';
import 'notebooks_screen.dart';
import 'security_settings_screen.dart';
import 'statistics_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  Notebook? _selectedNotebook;
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.updatedDesc; // Default sort
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

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
    _loadSortPreference();
    _loadNotes();
    _loadNotebooks();
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final sortKey = prefs.getString('note_sort_preference');
    if (sortKey != null) {
      setState(() {
        _currentSort = SortOption.values.firstWhere(
          (s) => s.key == sortKey,
          orElse: () => SortOption.updatedDesc,
        );
      });
    }
  }

  Future<void> _saveSortPreference(SortOption sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('note_sort_preference', sort.key);
  }

  void _applySorting() {
    switch (_currentSort) {
      case SortOption.updatedDesc:
        _filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortOption.updatedAsc:
        _filteredNotes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SortOption.createdDesc:
        _filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.createdAsc:
        _filteredNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.titleAsc:
        _filteredNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortOption.titleDesc:
        _filteredNotes.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case SortOption.colorAsc:
        _filteredNotes.sort((a, b) => a.color.compareTo(b.color));
      case SortOption.colorDesc:
        _filteredNotes.sort((a, b) => b.color.compareTo(a.color));
      case SortOption.sizeDesc:
        _filteredNotes.sort((a, b) => b.content.length.compareTo(a.content.length));
      case SortOption.sizeAsc:
        _filteredNotes.sort((a, b) => a.content.length.compareTo(b.content.length));
    }
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
        _applySorting();
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
      await DatabaseService.instance.getAllNotebooks();
      // Notebooks loaded successfully but not stored in state
      // as they're only needed for navigation
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
        _applySorting();
      });
      return;
    }

    setState(() {
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
      _applySorting();
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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNoteIds.clear();
      }
    });
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNoteIds.addAll(_filteredNotes.map((n) => n.id));
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedNoteIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notes'),
        content: Text('Move ${_selectedNoteIds.length} note(s) to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final noteId in _selectedNoteIds) {
        await DatabaseService.instance.deleteNote(noteId);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes moved to trash')),
        );
      }
    }
  }

  Future<void> _bulkMove() async {
    if (_selectedNoteIds.isEmpty) return;

    final notebooks = await DatabaseService.instance.getAllNotebooks();
    if (!mounted) return;

    final selectedNotebook = await showDialog<Notebook?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Notebook'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notebooks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('No Notebook'),
                  onTap: () => Navigator.pop(context, null),
                );
              }
              final notebook = notebooks[index - 1];
              return ListTile(
                leading: Icon(Icons.folder, color: Color(notebook.color)),
                title: Text(notebook.name),
                onTap: () => Navigator.pop(context, notebook),
              );
            },
          ),
        ),
      ),
    );

    if (mounted) {
      for (final noteId in _selectedNoteIds) {
        final note = _notes.firstWhere((n) => n.id == noteId);
        final updatedNote = note.copyWith(
          notebookId: selectedNotebook?.id,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateNote(updatedNote);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedNotebook == null
                ? 'Notes removed from notebook'
                : 'Notes moved to ${selectedNotebook.name}',
          ),
        ),
      );
    }
  }

  Future<void> _bulkChangeColor() async {
    if (_selectedNoteIds.isEmpty) return;

    final selectedColor = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _noteColors.map((color) {
            return InkWell(
              onTap: () => Navigator.pop(context, color.value),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedColor != null && mounted) {
      for (final noteId in _selectedNoteIds) {
        final note = _notes.firstWhere((n) => n.id == noteId);
        final updatedNote = note.copyWith(
          color: selectedColor,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateNote(updatedNote);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Color updated')),
      );
    }
  }

  Future<void> _bulkAddTags() async {
    if (_selectedNoteIds.isEmpty) return;

    final tagController = TextEditingController();
    final tags = await showDialog<List<String>?>(
      context: context,
      builder: (context) {
        final tempTags = <String>[];
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Tags'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    hintText: 'Enter tag',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (tagController.text.isNotEmpty) {
                          setState(() {
                            tempTags.add(tagController.text.trim());
                            tagController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        tempTags.add(value.trim());
                        tagController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tempTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          tempTags.remove(tag);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, tempTags),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );

    if (tags != null && tags.isNotEmpty && mounted) {
      for (final noteId in _selectedNoteIds) {
        final note = _notes.firstWhere((n) => n.id == noteId);
        final updatedTags = {...note.tags, ...tags}.toList();
        final updatedNote = note.copyWith(
          tags: updatedTags,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateNote(updatedNote);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tags added')),
      );
    }
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
        title: _isSelectionMode
            ? Text('${_selectedNoteIds.length} selected')
            : _isSearching
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
        actions: _isSelectionMode
            ? [
                if (_selectedNoteIds.length < _filteredNotes.length)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: 'Select All',
                    onPressed: _selectAll,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel Selection',
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                PopupMenuButton<SortOption>(
                  icon: Icon(
                    Icons.sort,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  tooltip: 'Sort Notes',
                  onSelected: (SortOption sort) {
                    setState(() {
                      _currentSort = sort;
                      _applySorting();
                    });
                    _saveSortPreference(sort);
                  },
                  itemBuilder: (context) => SortOption.values.map((sort) {
                    return PopupMenuItem<SortOption>(
                      value: sort,
                      child: Row(
                        children: [
                          if (_currentSort == sort)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF2DBD6C),
                              size: 20,
                            )
                          else
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sort.displayName,
                              style: TextStyle(
                                fontWeight: _currentSort == sort ? FontWeight.bold : FontWeight.normal,
                                color: _currentSort == sort ? const Color(0xFF2DBD6C) : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.checklist,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  tooltip: 'Select Multiple',
                  onPressed: _toggleSelectionMode,
                ),
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
                        _applySorting();
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
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Security'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
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
      body: Column(
        children: [
          // Bulk action bar
          if (_isSelectionMode && _selectedNoteIds.isNotEmpty)
            Container(
              color: const Color(0xFF2DBD6C).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedNoteIds.length} note(s) selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2DBD6C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder, color: Color(0xFF2DBD6C)),
                    tooltip: 'Move to Notebook',
                    onPressed: _bulkMove,
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette, color: Color(0xFF2DBD6C)),
                    tooltip: 'Change Color',
                    onPressed: _bulkChangeColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.local_offer, color: Color(0xFF2DBD6C)),
                    tooltip: 'Add Tags',
                    onPressed: _bulkAddTags,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: _bulkDelete,
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: _isLoading
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
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'template',
            onPressed: _showTemplateOptions,
            tooltip: 'New from Template',
            child: const Icon(Icons.description, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'new',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RichNoteEditorScreen(availableColors: _noteColors),
                ),
              );
              if (result == true) {
                _loadNotes();
              }
            },
            tooltip: 'New Note',
            child: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
    );
  }

  void _showTemplateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Meeting Notes'),
              subtitle: const Text('Date, attendees, agenda, action items'),
              onTap: () {
                Navigator.pop(context);
                _openTemplateNote('meeting');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('To-Do List'),
              subtitle: const Text('Quick checklist template'),
              onTap: () {
                Navigator.pop(context);
                _openTemplateNote('todo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Journal Entry'),
              subtitle: const Text('Daily journal with prompts'),
              onTap: () {
                Navigator.pop(context);
                _openTemplateNote('journal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Recipe'),
              subtitle: const Text('Ingredients and instructions'),
              onTap: () {
                Navigator.pop(context);
                _openTemplateNote('recipe');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTemplateNote(String templateType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RichNoteEditorScreen(
          availableColors: _noteColors,
          templateType: templateType,
        ),
      ),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  Widget _buildNoteCard(Note note, bool isDark) {
    final cardColor = _getNoteColor(note.color, isDark);
    final cardIsLight = _isCardColorLight(note.color, isDark);
    final textColor = cardIsLight ? Colors.black87 : Colors.white;
    final secondaryTextColor = cardIsLight ? Colors.grey.shade700 : Colors.grey.shade300;
    final isSelected = _selectedNoteIds.contains(note.id);
    
    return Card(
      color: cardColor,
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected 
        ? const Color(0xFF2DBD6C).withOpacity(0.5)
        : Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected 
            ? const Color(0xFF2DBD6C) 
            : isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: isSelected ? 2 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (_isSelectionMode) {
            _toggleNoteSelection(note.id);
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RichNoteEditorScreen(note: note, availableColors: _noteColors),
              ),
            );
            if (result == true) {
              _loadNotes();
            }
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedNoteIds.add(note.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode) ...[
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleNoteSelection(note.id),
                      activeColor: const Color(0xFF2DBD6C),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
