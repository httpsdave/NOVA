class Attachment {
  final String id;
  final String noteId;
  final String filePath;
  final String fileName;
  final String fileType; // 'image', 'audio', 'file'
  final int fileSize;
  final DateTime createdAt;
  final String? caption; // Caption for images

  Attachment({
    required this.id,
    required this.noteId,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    this.caption,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'caption': caption,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      fileType: map['fileType'] as String,
      fileSize: map['fileSize'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      caption: map['caption'] as String?,
    );
  }

  Attachment copyWith({
    String? id,
    String? noteId,
    String? filePath,
    String? fileName,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    String? caption,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      caption: caption ?? this.caption,
    );
  }
}
