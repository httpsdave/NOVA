class SearchFilters {
  final String? notebookId;
  final String? color;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? hasAttachments;
  final bool? hasReminder;
  final bool? isPinned;
  final List<String>? tags;

  SearchFilters({
    this.notebookId,
    this.color,
    this.startDate,
    this.endDate,
    this.hasAttachments,
    this.hasReminder,
    this.isPinned,
    this.tags,
  });

  bool get hasActiveFilters =>
      notebookId != null ||
      color != null ||
      startDate != null ||
      endDate != null ||
      hasAttachments != null ||
      hasReminder != null ||
      isPinned != null ||
      (tags != null && tags!.isNotEmpty);

  int get activeFilterCount {
    int count = 0;
    if (notebookId != null) count++;
    if (color != null) count++;
    if (startDate != null || endDate != null) count++;
    if (hasAttachments == true) count++;
    if (hasReminder == true) count++;
    if (isPinned == true) count++;
    if (tags != null && tags!.isNotEmpty) count++;
    return count;
  }

  SearchFilters copyWith({
    String? notebookId,
    String? color,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasAttachments,
    bool? hasReminder,
    bool? isPinned,
    List<String>? tags,
    bool clearNotebook = false,
    bool clearColor = false,
    bool clearDates = false,
    bool clearAttachments = false,
    bool clearReminder = false,
    bool clearPinned = false,
    bool clearTags = false,
  }) {
    return SearchFilters(
      notebookId: clearNotebook ? null : (notebookId ?? this.notebookId),
      color: clearColor ? null : (color ?? this.color),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      hasAttachments: clearAttachments ? null : (hasAttachments ?? this.hasAttachments),
      hasReminder: clearReminder ? null : (hasReminder ?? this.hasReminder),
      isPinned: clearPinned ? null : (isPinned ?? this.isPinned),
      tags: clearTags ? null : (tags ?? this.tags),
    );
  }

  SearchFilters clearAll() {
    return SearchFilters();
  }
}
