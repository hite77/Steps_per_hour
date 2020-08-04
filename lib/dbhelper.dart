import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stepsperhour/weight.dart';

class DatabaseHelper {
  static final _databaseName = "weightdb.db";
  static final _databaseVersion = 1;

  static final table = 'weight_table';

  static final columnId = 'id';
  static final columnData = 'data';
  static final columnStart = 'start';
  static final columnEnd = 'end';
  static final columnAge = 'age';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it does not exist)
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  //SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $table (
    $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
    $columnData TEXT NOT NULL,
    $columnStart TEXT NOT NULL,
    $columnEnd TEXT NOT NULL,
    $columnAge INTEGER
    )
    ''');
  }

  Future<int> insert(Weight weight) async {
    Database db = await instance.database;
    return await db.insert(
      table,
      weight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  deleteAll() async {
    var dbEntries = await queryAllRows();
    dbEntries.forEach((element) async {
      await delete(element['id']);
    });
  }

  deleteOld() async {
    var dbEntries = await queryAllRows();
    dbEntries.forEach((element) async {
      var difference = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(element['age']))
          .inDays;
      if (difference > (31 * 8)) {
        await delete(element['id']);
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryRows(date) async {
    Database db = await instance.database;
    return await db.query(table, where: "$columnStart LIKE '%$date%'");
  }

  Future<int> update(Weight weight) async {
    Database db = await instance.database;
    int id = weight.toMap()['id'];
    return await db
        .update(table, weight.toMap(), where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
