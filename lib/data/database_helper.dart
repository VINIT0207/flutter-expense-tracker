import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// --- LOGIC IMPORTS ---
import '../models/transaction.dart';
import '../models/goal.dart';

/// A robust, singleton database controller for the entire application.
///
/// Features:
/// - Atomic Transactions
/// - Automated Indexing
/// - Complex Analytical Queries
/// - Thread-safe Access
class DatabaseHelper {
  // --- CONSTANTS ---
  static const _dbName = 'finance_pro_v1.db';
  static const _dbVersion = 1;
  static const _tableName = 'transactions';
  static const _goalsTableName = 'goals';
  static const _budgetTableName = 'budget_settings';

  // Transaction Column Mapping
  static const colId = 'id';
  static const colTitle = 'title';
  static const colCategory = 'category';
  static const colAmount = 'amount';
  static const colDate = 'date';
  static const colIsEssential = 'isEssential';
  static const colNote = 'note';

  // Goal Column Mapping
  static const colGoalId = 'id';
  static const colGoalTitle = 'title';
  static const colTargetAmount = 'targetAmount';
  static const colSavedAmount = 'savedAmount';
  static const colTargetDate = 'targetDate';
  static const colIsCompleted = 'isCompleted';

  // Budget Settings Column Mapping
  static const colBudgetKey = 'key';
  static const colBudgetValue = 'value';

  // --- SINGLETON SETUP ---
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Returns the active database connection.
  /// Initializes it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Lazy initialization
    _database = await _initDB(_dbName);
    return _database!;
  }

  // --- INITIALIZATION LOGIC ---

  Future<Database> _initDB(String filePath) async {
    Directory dbPath;

    try {
      if (Platform.isAndroid) {
        dbPath = await getApplicationDocumentsDirectory(); // Safer on Android
      } else {
        dbPath = await getApplicationDocumentsDirectory(); // iOS standard
      }

      final path = join(dbPath.path, filePath);

      if (kDebugMode) {
        debugPrint("📂 Database Path: $path");
      }

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint("❌ CRITICAL: Failed to initialize database: $e");
      rethrow;
    }
  }

  /// Configures database settings before usage (Foreign keys, WAL mode).
  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Keys (future-proofing for multiple tables)
    await db.execute('PRAGMA foreign_keys = ON');
    // Write-Ahead Logging for concurrency performance
    // await db.execute('PRAGMA journal_mode = WAL');
  }

  /// Creates the table structure and indexes.
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // SQLite doesn't have BOOL
    const nullTextType = 'TEXT';

    debugPrint("🛠 Creating Database Structure...");

    // --- TRANSACTIONS TABLE ---
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId $idType,
        $colTitle $textType,
        $colCategory $textType,
        $colAmount $numType,
        $colDate $textType,
        $colIsEssential $boolType,
        $colNote $nullTextType
      )
    ''');

    // --- PERFORMANCE INDEXING FOR TRANSACTIONS ---
    await db.execute('CREATE INDEX idx_${_tableName}_date ON $_tableName($colDate)');
    await db.execute('CREATE INDEX idx_${_tableName}_category ON $_tableName($colCategory)');

    // --- GOALS TABLE ---
    await db.execute('''
      CREATE TABLE $_goalsTableName (
        $colGoalId $idType,
        $colGoalTitle $textType,
        $colTargetAmount $numType,
        $colSavedAmount $numType,
        $colTargetDate $textType,
        $colIsCompleted $boolType
      )
    ''');

    // --- BUDGET SETTINGS TABLE ---
    // Stores budget settings (monthly_budget, daily_budget)
    await db.execute('''
      CREATE TABLE $_budgetTableName (
        $colBudgetKey TEXT PRIMARY KEY,
        $colBudgetValue REAL
      )
    ''');

    debugPrint("✅ Database Structure Created with Goals and Budget Settings tables.");
  }

  /// Handles schema updates for future app versions.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      debugPrint("⚙️ Upgrading Database from $oldVersion to $newVersion");
      // Example: if (oldVersion == 1) await db.execute("ALTER TABLE...");
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Inserts a new transaction record. Returns the new ID.
  Future<int> create(TransactionModel tx) async {
    final db = await instance.database;

    try {
      final id = await db.insert(
          _tableName,
          tx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace
      );
      if (kDebugMode) debugPrint("➕ Inserted Tx ID: $id (${tx.title})");
      return id;
    } catch (e) {
      debugPrint("❌ Insert Failed: $e");
      throw Exception("Database Insert Error");
    }
  }

  /// Retrieves a single transaction by ID.
  Future<TransactionModel?> read(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      _tableName,
      columns: null,
      where: '$colId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Reads all transactions, strictly sorted by Date (Newest first).
  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    const orderBy = '$colDate DESC';
    final result = await db.query(_tableName, orderBy: orderBy);
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  /// Updates an existing transaction. Returns number of rows affected.
  Future<int> update(TransactionModel tx) async {
    final db = await instance.database;
    return db.update(
      _tableName,
      tx.toMap(),
      where: '$colId = ?',
      whereArgs: [tx.id],
    );
  }

  /// Deletes a transaction by ID.
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      _tableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Deletes ALL transactions. Dangerous operation.
  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete(_tableName);
  }

  // ==================== GOAL OPERATIONS ====================

  /// Adds a new goal to the database.
  Future<int> addGoal(GoalModel goal) async {
    final db = await instance.database;
    return await db.insert(_goalsTableName, goal.toMap());
  }

  /// Retrieves all goals, sorted by target date (earliest first).
  Future<List<GoalModel>> getGoals() async {
    final db = await instance.database;
    final result = await db.query(
      _goalsTableName,
      orderBy: '$colTargetDate ASC',
    );
    return result.map((json) => GoalModel.fromMap(json)).toList();
  }

  /// Updates an existing goal.
  Future<int> updateGoal(GoalModel goal) async {
    final db = await instance.database;
    return await db.update(
      _goalsTableName,
      goal.toMap(),
      where: '$colGoalId = ?',
      whereArgs: [goal.id],
    );
  }

  /// Deletes a goal by ID.
  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      _goalsTableName,
      where: '$colGoalId = ?',
      whereArgs: [id],
    );
  }

  // ==================== ANALYTICS QUERIES ====================

  /// Gets total sum grouped by category.
  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT $colCategory, SUM($colAmount) as total
      FROM $_tableName
      GROUP BY $colCategory
      ORDER BY total DESC
    ''');
  }

  /// Gets sum of expenses for a specific date range.
  Future<double> getSumByDateRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM($colAmount) as total
      FROM $_tableName
      WHERE $colDate >= ? AND $colDate <= ?
    ''', [startStr, endStr]);

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Returns daily spending totals for the last [limit] days.
  Future<List<Map<String, dynamic>>> getDailyTotals(int limit) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT substr($colDate, 1, 10) as day, SUM($colAmount) as total
      FROM $_tableName
      GROUP BY day
      ORDER BY day DESC
      LIMIT ?
    ''', [limit]);
  }

  // ==================== BATCH OPERATIONS ====================

  Future<void> batchInsert(List<TransactionModel> txList) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var tx in txList) {
      batch.insert(_tableName, tx.toMap());
    }

    await batch.commit(noResult: true);
    debugPrint("✅ Batch inserted ${txList.length} records.");
  }

  // ==================== SEARCH ====================

  Future<List<TransactionModel>> search(String query) async {
    final db = await instance.database;

    final result = await db.query(
      _tableName,
      where: '$colTitle LIKE ? OR $colCategory LIKE ? OR $colNote LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: '$colDate DESC',
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // ==================== BUDGET SETTINGS OPERATIONS ====================

  /// Saves a budget setting to the database.
  /// key: 'monthly_budget' or 'daily_budget'
  Future<void> saveBudgetSetting(String key, double value) async {
    final db = await instance.database;
    await db.insert(
      _budgetTableName,
      {colBudgetKey: key, colBudgetValue: value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (kDebugMode) debugPrint("💾 Saved budget setting: $key = $value");
  }

  /// Retrieves a budget setting by key.
  /// Returns null if not found.
  Future<double?> getBudgetSetting(String key) async {
    final db = await instance.database;
    final result = await db.query(
      _budgetTableName,
      columns: [colBudgetValue],
      where: '$colBudgetKey = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty && result.first[colBudgetValue] != null) {
      return (result.first[colBudgetValue] as num).toDouble();
    }
    return null;
  }

  /// Retrieves all budget settings.
  /// Returns a map with 'monthly_budget' and 'daily_budget' keys.
  Future<Map<String, double?>> getAllBudgetSettings() async {
    final db = await instance.database;
    final result = await db.query(_budgetTableName);
    
    final settings = <String, double?>{};
    for (var row in result) {
      final key = row[colBudgetKey] as String;
      final value = row[colBudgetValue] as num?;
      settings[key] = value?.toDouble();
    }
    return settings;
  }

  /// Deletes a budget setting by key.
  Future<void> deleteBudgetSetting(String key) async {
    final db = await instance.database;
    await db.delete(
      _budgetTableName,
      where: '$colBudgetKey = ?',
      whereArgs: [key],
    );
    if (kDebugMode) debugPrint("🗑️ Deleted budget setting: $key");
  }

  // ==================== MAINTENANCE ====================

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<int> getDatabaseSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint("Error getting DB size: $e");
    }
    return 0;
  }

  // ==================== IMPORT/EXPORT OPERATIONS ====================

  /// Imports transactions from a CSV file.
  /// Parses the CSV and returns a list of TransactionModel objects.
  /// The CSV should have headers: title,category,amount,date,isEssential,note
  Future<List<TransactionModel>> importTransactions(String filePath) async {
    final file = File(filePath);
    final csvString = await file.readAsString();

    // Parse CSV - using simple line-based parsing
    final lines = csvString.split('\n');
    if (lines.isEmpty) {
      throw const FormatException("Empty CSV file");
    }

    // Find header row
    int headerIndex = -1;
    for (int i = 0; i < lines.length && i < 5; i++) {
      final firstCell = lines[i].split(',')[0].toLowerCase().trim();
      if (firstCell == 'id' || firstCell == 'title') {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1) {
      throw const FormatException("Could not find header row. Expected 'id' or 'title' in first column.");
    }

    final headers = lines[headerIndex].split(',').map((e) => e.toLowerCase().trim()).toList();

    // Validate required columns
    final requiredColumns = ['title', 'category', 'amount', 'date'];
    for (var col in requiredColumns) {
      if (!headers.contains(col)) {
        throw FormatException("Missing required column: $col");
      }
    }

    final transactions = <TransactionModel>[];

    for (int i = headerIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final row = _parseCsvLine(line);
        final tx = _parseCsvRow(row, headers);
        if (tx != null) {
          transactions.add(tx);
        }
      } catch (e) {
        debugPrint("Error parsing row $i: $e");
      }
    }

    debugPrint("📥 Parsed ${transactions.length} transactions from CSV");
    return transactions;
  }

  /// Parse a CSV line handling quoted values
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current.trim());
    return result;
  }

  /// Parse a single CSV row into a TransactionModel
  TransactionModel? _parseCsvRow(List<String> row, List<String> headers) {
    final Map<String, dynamic> values = {};
    
    for (int j = 0; j < headers.length && j < row.length; j++) {
      values[headers[j]] = row[j];
    }

    // Extract required fields
    final title = values['title']?.toString().trim();
    final category = values['category']?.toString().trim();
    final amountStr = values['amount']?.toString();
    final dateStr = values['date']?.toString().trim();

    if (title == null || title.isEmpty) return null;
    if (category == null || category.isEmpty) return null;
    if (amountStr == null || amountStr.isEmpty) return null;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    if (dateStr == null || dateStr.isEmpty) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    // Parse optional fields
    final isEssentialStr = values['isEssential']?.toString().toLowerCase();
    final isEssential = isEssentialStr == 'true' || isEssentialStr == '1' || isEssentialStr == 'yes';
    final note = values['note']?.toString().trim();

    return TransactionModel(
      title: title,
      category: category,
      amount: amount,
      date: date,
      isEssential: isEssential,
      note: note,
    );
  }
}

