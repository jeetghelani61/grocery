import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static final _databaseName = "topstech.db";
  static final _databaseVersion = 1;

  static final table = 'category';
  static final table2 = 'contact';

  // Table 1 columns
  static final columnId = '_id';
  static final columnName = 'category_name';

  // Table 2 columns
  static final columnId1 = '_id';
  static final columnCName = 'company_name';
  static final columnPName = 'product_name';
  static final columnType = 'type_mob';

  // --- 1. Define the new column variables ---
  static final columnImage = 'image';
  static final columnPrice = 'price';

  DbHelper._privateConstructor();

  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async =>
      _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL
      )
    ''');

    // --- 2. Fix the CREATE TABLE statement for table2 ---
    await db.execute('''
      CREATE TABLE $table2 (
        $columnId1 INTEGER PRIMARY KEY,
        $columnCName TEXT NOT NULL,
        $columnPName TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnImage BLOB,
        $columnPrice REAL
      )
    ''');
  }

  // Insert Category
  Future<int> insertCategory(Map<String, dynamic> row) async {
    var db = await instance.database;
    return await db.insert(table, row);
  }

  // Insert Contact
  Future<int> insertContact(Map<String, dynamic> row) async {
    var db = await instance.database;
    return await db.insert(table2, row);
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    var db = await instance.database;
    return await db.query(table);
  }

  // Get all contacts
  Future<List<Map<String, dynamic>>> queryAllContacts() async {
    var db = await instance.database;
    return await db.query(table2, orderBy: '$columnId1 DESC');
  }

  // Update Contact
  Future<int> updateContact(Map<String, dynamic> row) async {
    var db = await instance.database;
    int id = row[columnId1];
    return await db.update(
        table2, row, where: '$columnId1 = ?', whereArgs: [id]);
  }

  // Delete contact by ID
  Future<int> deleteContact(int id) async {
    var db = await instance.database;
    return await db.delete(table2, where: '$columnId1 = ?', whereArgs: [id]);
  }
}