import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/notebook.dart';
import '../models/attachment.dart';
import '../models/note_version.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nova.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 6, // Increment version for version history
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN htmlContent TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN filePath TEXT');
    }
    if (oldVersion < 3) {
      // Add trash/recycle bin columns
      await db.execute('ALTER TABLE notes ADD COLUMN isDeleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN deletedAt TEXT');
    }
    if (oldVersion < 4) {
      // Add notebooks table and notebookId to notes
      await db.execute('''
        CREATE TABLE notebooks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          icon TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE notes ADD COLUMN notebookId TEXT');
    }
    if (oldVersion < 5) {
      // Add attachments table
      await db.execute('''
        CREATE TABLE attachments (
          id TEXT PRIMARY KEY,
          noteId TEXT NOT NULL,
          filePath TEXT NOT NULL,
          fileName TEXT NOT NULL,
          fileType TEXT NOT NULL,
          fileSize INTEGER NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add note versions table for version history
      await db.execute('''
        CREATE TABLE note_versions (
          id TEXT PRIMARY KEY,
          noteId TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          htmlContent TEXT,
          description TEXT,
          tags TEXT,
          createdAt TEXT NOT NULL,
          color INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        title $textType,
        content $textType,
        htmlContent TEXT,
        description TEXT,
        tags TEXT,
        createdAt $textType,
        updatedAt $textType,
        color $intType,
        isPinned $intType,
        reminderDateTime TEXT,
        filePath TEXT,
        isDeleted INTEGER DEFAULT 0,
        deletedAt TEXT,
        notebookId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notebooks (
        id $idType,
        name $textType,
        color $intType,
        icon $textType,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        description $textType,
        dueDate $textType,
        isCompleted $intType,
        createdAt $textType,
        completedAt TEXT,
        reminderDateTime TEXT,
        priority $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE attachments (
        id $idType,
        noteId $textType,
        filePath $textType,
        fileName $textType,
        fileType $textType,
        fileSize $intType,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE note_versions (
        id $idType,
        noteId $textType,
        title $textType,
        content $textType,
        htmlContent TEXT,
        description TEXT,
        tags TEXT,
        createdAt $textType,
        color $intType
      )
    ''');
  }

  // Notes operations
  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap());
    return note;
  }

  Future<List<Note>> getAllNotes() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'notes',
        where: 'isDeleted = ? OR isDeleted IS NULL',
        whereArgs: [0],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return result.map((map) => Note.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all notes: $e');
      return [];
    }
  }

  Future<List<Note>> getDeletedNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'isDeleted = ?',
      whereArgs: [1],
      orderBy: 'deletedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNote(String id) async {
    final db = await instance.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    
    // Create version history before updating
    final oldNote = await getNote(note.id);
    if (oldNote != null) {
      final version = NoteVersion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        noteId: oldNote.id,
        title: oldNote.title,
        content: oldNote.content,
        htmlContent: oldNote.htmlContent,
        description: oldNote.description,
        tags: oldNote.tags,
        createdAt: DateTime.now(),
        color: oldNote.color,
      );
      await createNoteVersion(version);
    }
    
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    // Soft delete - move to trash
    final db = await instance.database;
    return await db.update(
      'notes',
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreNote(String id) async {
    // Restore from trash
    final db = await instance.database;
    return await db.update(
      'notes',
      {
        'isDeleted': 0,
        'deletedAt': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDeleteNote(String id) async {
    // Permanently delete from database
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOldTrashNotes() async {
    // Delete notes that have been in trash for more than 30 days
    final db = await instance.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await db.delete(
      'notes',
      where: 'isDeleted = 1 AND deletedAt < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: '(title LIKE ? OR content LIKE ? OR description LIKE ? OR tags LIKE ?) AND isDeleted = 0',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  // Get related notes based on shared tags
  Future<List<Note>> getRelatedNotes(Note note, {int limit = 5}) async {
    if (note.tags.isEmpty) return [];
    
    final db = await instance.database;
    final tagConditions = note.tags.map((tag) => "tags LIKE '%$tag%'").join(' OR ');
    
    final result = await db.query(
      'notes',
      where: '($tagConditions) AND id != ? AND isDeleted = 0',
      whereArgs: [note.id],
      orderBy: 'updatedAt DESC',
      limit: limit,
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  // Tasks operations
  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      orderBy: 'isCompleted ASC, dueDate ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.query(
      'tasks',
      where: 'dueDate >= ? AND dueDate <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'isCompleted ASC, dueDate ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Notebooks operations
  Future<Notebook> createNotebook(Notebook notebook) async {
    final db = await instance.database;
    await db.insert('notebooks', notebook.toMap());
    return notebook;
  }

  Future<List<Notebook>> getAllNotebooks() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'notebooks',
        orderBy: 'createdAt DESC',
      );
      return result.map((map) => Notebook.fromMap(map)).toList();
    } catch (e) {
      print('Error getting notebooks: $e');
      return [];
    }
  }

  Future<Notebook?> getNotebook(String id) async {
    final db = await instance.database;
    final maps = await db.query('notebooks', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Notebook.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateNotebook(Notebook notebook) async {
    final db = await instance.database;
    return db.update(
      'notebooks',
      notebook.toMap(),
      where: 'id = ?',
      whereArgs: [notebook.id],
    );
  }

  Future<int> deleteNotebook(String id) async {
    final db = await instance.database;
    // Reset notebookId for all notes in this notebook
    await db.update(
      'notes',
      {'notebookId': null},
      where: 'notebookId = ?',
      whereArgs: [id],
    );
    return await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotesByNotebook(String notebookId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'notebookId = ? AND isDeleted = 0',
      whereArgs: [notebookId],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> getNotebookNoteCount(String notebookId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE notebookId = ? AND isDeleted = 0',
      [notebookId],
    );
    return result.first['count'] as int;
  }

  // Attachments operations
  Future<Attachment> createAttachment(Attachment attachment) async {
    final db = await instance.database;
    await db.insert('attachments', attachment.toMap());
    return attachment;
  }

  Future<List<Attachment>> getAttachmentsByNote(String noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'attachments',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Attachment.fromMap(map)).toList();
  }

  Future<int> deleteAttachment(String id) async {
    final db = await instance.database;
    return await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAttachmentsByNote(String noteId) async {
    final db = await instance.database;
    return await db.delete('attachments', where: 'noteId = ?', whereArgs: [noteId]);
  }

  // Note version history operations
  Future<NoteVersion> createNoteVersion(NoteVersion version) async {
    final db = await instance.database;
    await db.insert('note_versions', version.toMap());
    return version;
  }

  Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'note_versions',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => NoteVersion.fromMap(map)).toList();
  }

  Future<void> restoreNoteVersion(NoteVersion version) async {
    final db = await instance.database;
    
    // Get current note to preserve certain fields
    final currentNote = await getNote(version.noteId);
    if (currentNote == null) return;
    
    // Create a new version from current state before restoring
    final backupVersion = NoteVersion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      noteId: currentNote.id,
      title: currentNote.title,
      content: currentNote.content,
      htmlContent: currentNote.htmlContent,
      description: currentNote.description,
      tags: currentNote.tags,
      createdAt: DateTime.now(),
      color: currentNote.color,
    );
    await createNoteVersion(backupVersion);
    
    // Restore the note with version data, keeping some current fields
    await db.update(
      'notes',
      {
        'title': version.title,
        'content': version.content,
        'htmlContent': version.htmlContent,
        'description': version.description,
        'tags': version.tags.join(','),
        'color': version.color,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [version.noteId],
    );
  }

  Future<int> deleteNoteVersion(String id) async {
    final db = await instance.database;
    return await db.delete('note_versions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNoteVersionsByNote(String noteId) async {
    final db = await instance.database;
    return await db.delete('note_versions', where: 'noteId = ?', whereArgs: [noteId]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
