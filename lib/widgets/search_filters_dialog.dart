import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_filters.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';

class SearchFiltersDialog extends StatefulWidget {
  final SearchFilters currentFilters;

  const SearchFiltersDialog({
    super.key,
    required this.currentFilters,
  });

  @override
  State<SearchFiltersDialog> createState() => _SearchFiltersDialogState();
}

class _SearchFiltersDialogState extends State<SearchFiltersDialog> {
  late SearchFilters _filters;
  List<Notebook> _notebooks = [];
  List<String> _allTags = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Default', 'value': 'default', 'color': Colors.white},
    {'name': 'Red', 'value': 'red', 'color': const Color(0xFFFFF4E6)},
    {'name': 'Green', 'value': 'green', 'color': const Color(0xFFE8F5E9)},
    {'name': 'Blue', 'value': 'blue', 'color': const Color(0xFFE3F2FD)},
    {'name': 'Purple', 'value': 'purple', 'color': const Color(0xFFF3E5F5)},
    {'name': 'Pink', 'value': 'pink', 'color': const Color(0xFFFCE4EC)},
    {'name': 'Yellow', 'value': 'yellow', 'color': const Color(0xFFFFF9C4)},
    {'name': 'Teal', 'value': 'teal', 'color': const Color(0xFFE0F2F1)},
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final notebooks = await DatabaseService.instance.getAllNotebooks();
    final notes = await DatabaseService.instance.getAllNotes();
    
    // Extract unique tags
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }

    setState(() {
      _notebooks = notebooks;
      _allTags = tags.toList()..sort();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF2DBD6C)),
                        const SizedBox(width: 12),
                        const Text(
                          'Search Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Notebook Filter
                    _buildSectionTitle('Notebook'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _filters.notebookId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      hint: const Text('All Notebooks'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Notebooks'),
                        ),
                        ..._notebooks.map((notebook) => DropdownMenuItem<String?>(
                              value: notebook.id,
                              child: Text(notebook.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(
                            notebookId: value,
                            clearNotebook: value == null,
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Color Filter
                    _buildSectionTitle('Color'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((colorOption) {
                        final isSelected = _filters.color == colorOption['value'];
                        return FilterChip(
                          selected: isSelected,
                          label: Text(colorOption['name']),
                          avatar: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorOption['color'],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _filters = _filters.copyWith(
                                color: selected ? colorOption['value'] : null,
                                clearColor: !selected,
                              );
                            });
                          },
                          selectedColor: const Color(0xFF2DBD6C).withValues(alpha: 0.3),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Date Range Filter
                    _buildSectionTitle('Date Range'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectStartDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _filters.startDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_filters.startDate!)
                                  : 'Start Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('to'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectEndDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _filters.endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_filters.endDate!)
                                  : 'End Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_filters.startDate != null || _filters.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _filters = _filters.copyWith(clearDates: true);
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear Dates'),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Tags Filter
                    if (_allTags.isNotEmpty) ...[
                      _buildSectionTitle('Tags'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allTags.map((tag) {
                          final isSelected = _filters.tags?.contains(tag) ?? false;
                          return FilterChip(
                            selected: isSelected,
                            label: Text('#$tag'),
                            onSelected: (selected) {
                              setState(() {
                                List<String> tags = List.from(_filters.tags ?? []);
                                if (selected) {
                                  tags.add(tag);
                                } else {
                                  tags.remove(tag);
                                }
                                _filters = _filters.copyWith(
                                  tags: tags.isEmpty ? null : tags,
                                  clearTags: tags.isEmpty,
                                );
                              });
                            },
                            selectedColor: const Color(0xFF2DBD6C).withValues(alpha: 0.3),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Boolean Filters
                    _buildSectionTitle('Additional Filters'),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Has Attachments'),
                      value: _filters.hasAttachments ?? false,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(
                            hasAttachments: value,
                            clearAttachments: value == false,
                          );
                        });
                      },
                      activeColor: const Color(0xFF2DBD6C),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Has Reminder'),
                      value: _filters.hasReminder ?? false,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(
                            hasReminder: value,
                            clearReminder: value == false,
                          );
                        });
                      },
                      activeColor: const Color(0xFF2DBD6C),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Pinned Only'),
                      value: _filters.isPinned ?? false,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(
                            isPinned: value,
                            clearPinned: value == false,
                          );
                        });
                      },
                      activeColor: const Color(0xFF2DBD6C),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filters = SearchFilters();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context, _filters);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2DBD6C),
                            ),
                            child: Text(
                              _filters.hasActiveFilters
                                  ? 'Apply (${_filters.activeFilterCount})'
                                  : 'Apply',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filters.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _filters = _filters.copyWith(startDate: date);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filters.endDate ?? DateTime.now(),
      firstDate: _filters.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _filters = _filters.copyWith(endDate: date);
      });
    }
  }
}
