import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_tracker/models/taskEntry.dart';

import './models/task.dart';

class TaskDatabaseHelper {
  final String tableTask = 'tasks';
  final String columnId = '_id';
  final String columnTitle = 'title';
  final String columnColorHex = 'colorHex';
  final String columnIcon = 'icon';
  final String columnTaskDescription = 'taskDescription';
  final String columnUserUid = 'userUid';
  static final _databaseName = 'TaskDatabase.db';
  static final _databaseVersion = 1;

  TaskDatabaseHelper._privateConsructor();
  static final instance = TaskDatabaseHelper._privateConsructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) {
      return _database;
    } else {
      _database = await _initDatabase();
      return _database;
    }
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableTask(
          $columnId INTEGER PRIMARY KEY, 
          $columnTitle TEXT NOT NULL, 
          $columnColorHex TEXT NOT NULL, 
          $columnIcon TEXT NOT NULL, 
          $columnTaskDescription TEXT, 
          $columnUserUid TEXT NOT NULL
        )
    ''');
  }

  Future<int> insert(Task task) async {
    Database db = await database;
    int id = await db.insert(tableTask, task.toJson());
    return id;
  }

  Future<Task> queryTask(int id) async {
    if (database != null) {
      Database db = await database;
      var maps = await db.query(tableTask, where: '_id = ?', whereArgs: [id]);
      return maps.isNotEmpty ? Task.fromMap(maps.first) : null;
    } else {
      print('Database not exists');
      return null;
    }
  }

  deleteAll() async {
    if (database != null) {
      Database db = await database;
      db.delete(tableTask);
    } else {
      print('database not exists');
    }
  }
}

class TaskEntryDatabaseHelper {
  final String table = 'TaskEntry';
  final String columnId = '_id';
  final String columnBelongedTask = 'belongedTaskName';
  final String columnNote = 'note';
  final String columnStartTime = 'startTime';
  final String columnEndTime = 'endTime';
  final String columnDuration = 'duration';

  static final _databaseName = 'TaskEntryDatabase.db';
  static final _databaseVersion = 1;

  TaskEntryDatabaseHelper._privateConstructor();
  static final instance = TaskEntryDatabaseHelper._privateConstructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) {
      return _database;
    } else {
      _database = await _initDatabase();
      return _database;
    }
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table(
        $columnId INTEGER PRIMARY KEY, 
        $columnBelongedTask TEXT NOT NULL, 
        $columnNote TEXT, 
        $columnStartTime TEXT NOT NULL, 
        $columnEndTime TEXT NOT NULL, 
        $columnDuration TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(TaskEntry taskEntry) async {
    Database db = await database;
    int id = await db.insert(table, taskEntry.toMap());
    return id;
  }

  // Future query(int id) async {
  //   Database db = await database;
  //   var maps = await db.query(table, where: '_id = ?', whereArgs: [id]);
  //   return maps.isNotEmpty ? maps.first : 'id not exists';
  // }
  Future<TaskEntry> query(int id) async {
    Database db = await database;
    var maps = await db.query(table, where: '_id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? TaskEntry.fromMap(maps.first) : 'id not exists';
  }

  deleteAll() async {
    if (database != null) {
      Database db = await database;

      db.delete(table);
      print("Deleted table");
    } else {
      print('database not exists');
    }
  }
}