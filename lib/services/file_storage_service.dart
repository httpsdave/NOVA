import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/note.dart';

class FileStorageService {
  static final FileStorageService instance = FileStorageService._init();

  FileStorageService._init();

  Future<String> get _notesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(path.join(appDir.path, 'nova_notes'));
    
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    
    return notesDir.path;
  }

  // Save note as individual HTML file
  Future<String> saveNoteAsHtml(Note note) async {
    final dirPath = await _notesDirectory;
    final filePath = path.join(dirPath, '${note.id}.html');
    
    final htmlContent = _generateHtmlFile(note);
    final file = File(filePath);
    await file.writeAsString(htmlContent);
    
    return filePath;
  }

  // Read note from HTML file
  Future<String> readNoteHtml(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  // Delete note HTML file
  Future<void> deleteNoteHtml(String? filePath) async {
    if (filePath == null) return;
    
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Generate complete HTML file with metadata
  String _generateHtmlFile(Note note) {
    final tagsHtml = note.tags.map((tag) => '<span class="tag">$tag</span>').join(' ');
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="note-id" content="${note.id}">
    <meta name="created" content="${note.createdAt.toIso8601String()}">
    <meta name="updated" content="${note.updatedAt.toIso8601String()}">
    <meta name="tags" content="${note.tags.join(',')}">
    <title>${note.title}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            background-color: #f7f7f7;
        }
        .header {
            border-bottom: 2px solid #2DBD6C;
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        h1 {
            color: #2DBD6C;
            margin: 0 0 10px 0;
        }
        .description {
            color: #666;
            font-style: italic;
            margin-bottom: 10px;
        }
        .tags {
            margin: 10px 0;
        }
        .tag {
            display: inline-block;
            background-color: #2DBD6C;
            color: white;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 12px;
            margin-right: 5px;
        }
        .metadata {
            color: #999;
            font-size: 12px;
            margin-top: 10px;
        }
        .content {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>${note.title}</h1>
        ${note.description.isNotEmpty ? '<div class="description">${note.description}</div>' : ''}
        ${note.tags.isNotEmpty ? '<div class="tags">$tagsHtml</div>' : ''}
        <div class="metadata">
            <span>Created: ${_formatDate(note.createdAt)}</span> | 
            <span>Updated: ${_formatDate(note.updatedAt)}</span>
        </div>
    </div>
    <div class="content">
        ${note.htmlContent.isNotEmpty ? note.htmlContent : '<p>${note.content}</p>'}
    </div>
</body>
</html>
''';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Export all notes to a directory
  Future<String> exportAllNotes(List<Note> notes) async {
    final exportDir = Directory(path.join((await _notesDirectory), 'exports_${DateTime.now().millisecondsSinceEpoch}'));
    await exportDir.create(recursive: true);
    
    for (final note in notes) {
      final htmlContent = _generateHtmlFile(note);
      final fileName = '${note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.html';
      final file = File(path.join(exportDir.path, fileName));
      await file.writeAsString(htmlContent);
    }
    
    return exportDir.path;
  }
}
