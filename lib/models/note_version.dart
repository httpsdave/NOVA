class NoteVersion {
  final String id;
  final String noteId;
  final String title;
  final String content;
  final String htmlContent;
  final String description;
  final List<String> tags;
  final DateTime createdAt;
  final int color;

  NoteVersion({
    required this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.htmlContent,
    required this.description,
    required this.tags,
    required this.createdAt,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'title': title,
      'content': content,
      'htmlContent': htmlContent,
      'description': description,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'color': color,
    };
  }

  factory NoteVersion.fromMap(Map<String, dynamic> map) {
    return NoteVersion(
      id: map['id'],
      noteId: map['noteId'],
      title: map['title'],
      content: map['content'],
      htmlContent: map['htmlContent'] ?? '',
      description: map['description'] ?? '',
      tags: map['tags'] != null && map['tags'].isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      createdAt: DateTime.parse(map['createdAt']),
      color: map['color'],
    );
  }
}
