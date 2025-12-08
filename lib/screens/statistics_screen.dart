import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/notebook.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  
  int _totalNotes = 0;
  int _totalTasks = 0;
  int _notesThisWeek = 0;
  int _notesThisMonth = 0;
  int _completedTasks = 0;
  int _totalAttachments = 0;
  int _audioAttachments = 0;
  int _imageAttachments = 0;
  int _drawingAttachments = 0;
  
  List<MapEntry<String, int>> _topTags = [];
  List<MapEntry<String, int>> _topNotebooks = [];
  List<MapEntry<String, int>> _colorDistribution = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    final db = DatabaseService.instance;
    final notes = await db.getAllNotes();
    final tasks = await db.getAllTasks();
    final notebooks = await db.getAllNotebooks();

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    // Count notes by time
    _notesThisWeek = notes.where((n) => n.createdAt.isAfter(weekAgo)).length;
    _notesThisMonth = notes.where((n) => n.createdAt.isAfter(monthAgo)).length;

    // Count tasks
    _completedTasks = tasks.where((t) => t.isCompleted).length;

    // Count attachments
    _totalAttachments = 0;
    _audioAttachments = 0;
    _imageAttachments = 0;
    _drawingAttachments = 0;

    for (final note in notes) {
      final attachments = await db.getAttachmentsByNote(note.id);
      _totalAttachments += attachments.length;
      for (final attachment in attachments) {
        if (attachment.fileType == 'audio') _audioAttachments++;
        if (attachment.fileType == 'image') _imageAttachments++;
        if (attachment.fileType == 'drawing') _drawingAttachments++;
      }
    }

    // Count tags
    final Map<String, int> tagCounts = {};
    for (final note in notes) {
      for (final tag in note.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    _topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topTags = _topTags.take(5).toList();

    // Count notebooks
    final Map<String, int> notebookCounts = {};
    for (final note in notes) {
      if (note.notebookId != null) {
        final notebook = notebooks.firstWhere(
          (n) => n.id == note.notebookId,
          orElse: () => Notebook(id: '', name: 'Unknown', createdAt: DateTime.now()),
        );
        notebookCounts[notebook.name] = (notebookCounts[notebook.name] ?? 0) + 1;
      }
    }
    _topNotebooks = notebookCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topNotebooks = _topNotebooks.take(5).toList();

    // Count colors
    final Map<String, int> colorCounts = {};
    final colorNames = {
      'default': 'Default',
      'red': 'Red',
      'orange': 'Orange',
      'yellow': 'Yellow',
      'green': 'Green',
      'blue': 'Blue',
      'purple': 'Purple',
      'pink': 'Pink',
    };
    for (final note in notes) {
      final colorName = colorNames[note.color] ?? 'Default';
      colorCounts[colorName] = (colorCounts[colorName] ?? 0) + 1;
    }
    _colorDistribution = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _totalNotes = notes.length;
      _totalTasks = tasks.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview Cards
                  _buildSectionTitle('Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.note,
                          label: 'Total Notes',
                          value: _totalNotes.toString(),
                          color: const Color(0xFF2DBD6C),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          label: 'Tasks',
                          value: '$_completedTasks/$_totalTasks',
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today,
                          label: 'This Week',
                          value: _notesThisWeek.toString(),
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_month,
                          label: 'This Month',
                          value: _notesThisMonth.toString(),
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Attachments
                  _buildSectionTitle('Attachments'),
                  const SizedBox(height: 12),
                  _buildListCard(
                    isDark: isDark,
                    children: [
                      _buildStatRow(Icons.attach_file, 'Total Attachments', _totalAttachments.toString(), isDark),
                      _buildStatRow(Icons.mic, 'Voice Recordings', _audioAttachments.toString(), isDark),
                      _buildStatRow(Icons.image, 'Images', _imageAttachments.toString(), isDark),
                      _buildStatRow(Icons.brush, 'Drawings', _drawingAttachments.toString(), isDark),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Top Tags
                  _buildSectionTitle('Most Used Tags'),
                  const SizedBox(height: 12),
                  _buildListCard(
                    isDark: isDark,
                    children: _topTags.isEmpty
                        ? [_buildEmptyState('No tags yet', isDark)]
                        : _topTags.map((entry) => 
                            _buildStatRow(Icons.tag, entry.key, entry.value.toString(), isDark)
                          ).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Top Notebooks
                  _buildSectionTitle('Most Active Notebooks'),
                  const SizedBox(height: 12),
                  _buildListCard(
                    isDark: isDark,
                    children: _topNotebooks.isEmpty
                        ? [_buildEmptyState('No notebooks yet', isDark)]
                        : _topNotebooks.map((entry) => 
                            _buildStatRow(Icons.folder, entry.key, entry.value.toString(), isDark)
                          ).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Color Distribution
                  _buildSectionTitle('Color Distribution'),
                  const SizedBox(height: 12),
                  _buildListCard(
                    isDark: isDark,
                    children: _colorDistribution.map((entry) => 
                        _buildStatRow(Icons.palette, entry.key, entry.value.toString(), isDark)
                      ).toList(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2DBD6C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
