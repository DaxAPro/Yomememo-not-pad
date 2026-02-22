import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note_model.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT'; // ✅ Changed to const
    const textType = 'TEXT NOT NULL'; // ✅ Changed to const
    const boolType = 'BOOLEAN NOT NULL'; // ✅ Changed to const
    const integerType = 'INTEGER NOT NULL'; // ✅ Changed to const

    await db.execute('''
CREATE TABLE $tableNotes ( 
  ${NoteFields.id} $idType, 
  ${NoteFields.isPinned} $boolType,
  ${NoteFields.isChecklist} $boolType,
  ${NoteFields.isTrashed} $boolType,
  ${NoteFields.title} $textType,
  ${NoteFields.content} $textType,
  ${NoteFields.category} $textType,
  ${NoteFields.color} $integerType,
  ${NoteFields.createdTime} $textType
  )
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS $tableNotes');
      await _createDB(db, newVersion);
    }
  }

  Future<Note> create(Note note) async {
    final db = await instance.database;
    final id = await db.insert(tableNotes, note.toJson());
    return note.copy(id: id);
  }

  Future<Note> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    const orderBy = '${NoteFields.createdTime} DESC'; // ✅ Changed to const

    final result = await db.query(tableNotes,
        where: '${NoteFields.isTrashed} = ?', whereArgs: [0], orderBy: orderBy);

    return result.map((json) => Note.fromJson(json)).toList();
  }

  Future<List<Note>> readTrashedNotes() async {
    final db = await instance.database;
    const orderBy = '${NoteFields.createdTime} DESC'; // ✅ Changed to const

    final result = await db.query(
      tableNotes,
      where: '${NoteFields.isTrashed} = ?',
      whereArgs: [1],
      orderBy: orderBy,
    );

    return result.map((json) => Note.fromJson(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return db.update(
      tableNotes,
      note.toJson(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

  // ✅ App එකේ Lag එකක් නැතිව සියල්ල එකවර මකා දමන අලුත් function එක
  Future<int> deleteAllNotes() async {
    final db = await instance.database;
    return await db.delete(tableNotes);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
