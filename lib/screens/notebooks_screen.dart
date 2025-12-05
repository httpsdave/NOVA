import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';

class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  List<Notebook> _notebooks = [];
  Map<String, int> _noteCounts = {};
  bool _isLoading = true;

  final List<int> _colors = [
    0xFF2DBD6C, // Nova green
    0xFFFF6B6B, // Red
    0xFF4ECDC4, // Teal
    0xFFFFE66D, // Yellow
    0xFF95E1D3, // Mint
    0xFFA8E6CF, // Light green
    0xFFFFAA9C, // Coral
    0xFFB4A7D6, // Lavender
  ];

  final List<Map<String, dynamic>> _icons = [
    {'icon': Icons.folder, 'name': 'folder'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.home, 'name': 'home'},
    {'icon': Icons.favorite, 'name': 'favorite'},
    {'icon': Icons.star, 'name': 'star'},
    {'icon': Icons.lightbulb, 'name': 'lightbulb'},
    {'icon': Icons.book, 'name': 'book'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    setState(() => _isLoading = true);
    try {
      final notebooks = await DatabaseService.instance.getAllNotebooks();
      final Map<String, int> counts = {};
      
      for (final notebook in notebooks) {
        try {
          final count = await DatabaseService.instance.getNotebookNoteCount(notebook.id);
          counts[notebook.id] = count;
        } catch (e) {
          counts[notebook.id] = 0;
        }
      }

      setState(() {
        _notebooks = notebooks;
        _noteCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notebooks: $e')),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'folder': Icons.folder,
      'work': Icons.work,
      'school': Icons.school,
      'home': Icons.home,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'lightbulb': Icons.lightbulb,
      'book': Icons.book,
    };
    return iconMap[iconName] ?? Icons.folder;
  }

  Future<void> _showNotebookDialog({Notebook? notebook}) async {
    final isEdit = notebook != null;
    final nameController = TextEditingController(text: notebook?.name ?? '');
    int selectedColor = notebook?.color ?? _colors[0];
    String selectedIcon = notebook?.icon ?? 'folder';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Notebook' : 'New Notebook'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colors.map((color) {
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icons.map((iconData) {
                      final isSelected = iconData['name'] == selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedIcon = iconData['name']);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(selectedColor).withValues(alpha: 0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Color(selectedColor), width: 2)
                                : null,
                          ),
                          child: Icon(
                            iconData['icon'],
                            color: isSelected ? Color(selectedColor) : Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  if (isEdit) {
                    final updated = notebook.copyWith(
                      name: nameController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                    );
                    await DatabaseService.instance.updateNotebook(updated);
                  } else {
                    final newNotebook = Notebook(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                      createdAt: DateTime.now(),
                    );
                    await DatabaseService.instance.createNotebook(newNotebook);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadNotebooks();
                  }
                },
                child: Text(isEdit ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteNotebook(Notebook notebook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook'),
        content: Text(
          'Delete "${notebook.name}"? Notes in this notebook will not be deleted.',
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
      await DatabaseService.instance.deleteNotebook(notebook.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notebook deleted')),
        );
        _loadNotebooks();
      }
    }
  }

  bool _isColorLight(int colorValue) {
    final color = Color(colorValue);
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebooks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notebooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notebooks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create notebooks to organize your notes',
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
                  itemCount: _notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = _notebooks[index];
                    final noteCount = _noteCounts[notebook.id] ?? 0;
                    final isLight = _isColorLight(notebook.color);

                    return Card(
                      color: Color(notebook.color),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          _getIconData(notebook.icon),
                          color: isLight ? Colors.black87 : Colors.white,
                          size: 32,
                        ),
                        title: Text(
                          notebook.name,
                          style: TextStyle(
                            color: isLight ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: isLight ? Colors.black87 : Colors.white,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showNotebookDialog(notebook: notebook);
                            } else if (value == 'delete') {
                              _deleteNotebook(notebook);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context, notebook);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNotebookDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
