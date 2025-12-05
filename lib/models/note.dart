class Note {
  final String id;
  final String title;
  final String content; // Plain text for search
  final String htmlContent; // Rich HTML content
  final String description; // Short description
  final List<String> tags; // Tags for organization
  final DateTime createdAt;
  final DateTime updatedAt;
  final int color;
  final bool isPinned;
  final DateTime? reminderDateTime;
  final String? filePath; // Path to individual HTML file

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.htmlContent = '',
    this.description = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color = 0xFFFFFFFF,
    this.isPinned = false,
    this.reminderDateTime,
    this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'htmlContent': htmlContent,
      'description': description,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'filePath': filePath,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String? ?? '';
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      htmlContent: map['htmlContent'] as String? ?? '',
      description: map['description'] as String? ?? '',
      tags: tagsString.isEmpty ? [] : tagsString.split(','),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      color: map['color'] as int,
      isPinned: map['isPinned'] == 1,
      reminderDateTime: map['reminderDateTime'] != null
          ? DateTime.parse(map['reminderDateTime'] as String)
          : null,
      filePath: map['filePath'] as String?,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? htmlContent,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? color,
    bool? isPinned,
    DateTime? reminderDateTime,
    String? filePath,
    bool clearReminder = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      htmlContent: htmlContent ?? this.htmlContent,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      reminderDateTime: clearReminder
          ? null
          : (reminderDateTime ?? this.reminderDateTime),
      filePath: filePath ?? this.filePath,
    );
  }
}
