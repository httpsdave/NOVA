import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/task.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment version for schema update
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN htmlContent TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN filePath TEXT');
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
        filePath TEXT
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
  }

  // Notes operations
  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap());
    return note;
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      orderBy: 'isPinned DESC, updatedAt DESC',
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
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ? OR description LIKE ? OR tags LIKE ?',
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
      where: '($tagConditions) AND id != ?',
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

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
