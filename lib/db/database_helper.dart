import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workflow.db');
    print('Database path: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workflows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        creation_date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workflow_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        parameters TEXT,
        task_order INTEGER NOT NULL,
        FOREIGN KEY (workflow_id) REFERENCES workflows (id)
      )
    ''');
  }

  Future<int> insertTask(Map<String, dynamic> taskData) async {
    final db = await database;
    return await db.insert('tasks', taskData);
  }

  Future<List<Map<String, dynamic>>> getTasks(int workflowId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'workflow_id = ?',
      whereArgs: [workflowId],
    );
  }

  Future<int> updateTask(int taskId, Map<String, dynamic> taskData) async {
    final db = await database;
    return await db.update(
      'tasks',
      taskData,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteTask(int taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteWorkflow(int id) async {
    final db = await database;
    await db.delete('workflows', where: 'id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'workflow_id = ?', whereArgs: [id]);
    print('Deleted workflow with ID: $id');
  }

  Future<void> updateWorkflow(int id, String name, String status) async {
    final db = await database;
    await db.update(
      'workflows',
      {'name': name, 'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
