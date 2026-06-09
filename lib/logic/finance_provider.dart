import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../data/database_helper.dart';
import '../utils/import_export_helper.dart';

/// Manages the application state, handles database interactions,
/// and provides real-time financial analytics.
class FinanceProvider with ChangeNotifier {
  // --- STATE ---
  List<TransactionModel> _transactions = [];
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;
  double _monthlyBudget = 15000.0;
  double? _dailyBudget;

  // --- GETTERS ---
  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get monthlyBudget => _monthlyBudget;
  double? get dailyBudget => _dailyBudget;

  // --- SMART CALCULATIONS ---

  /// Total amount you need to set aside TODAY to stay on track for all active goals.
  double get totalDailySavingsRequired {
    double total = 0;
    for (var goal in _goals) {
      if (!goal.isCompleted && goal.savedAmount < goal.targetAmount) {
        total += goal.dailySavingsNeeded;
      }
    }
    return total;
  }

  /// Your "True" Monthly Budget (Total Budget - What you need to save for goals this month)
  double get effectiveMonthlyBudget {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDay - now.day + 1;
    
    // Reserve money needed for goals this month
    return _monthlyBudget - (totalDailySavingsRequired * daysRemaining);
  }

  /// Total spent in the current calendar month
  double get totalSpentMonth {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Total spent specifically today
  double get spentToday {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculates the percentage of budget used (0.0 to 1.0+)
  double get budgetProgress => totalSpentMonth / (_monthlyBudget > 0 ? _monthlyBudget : 1);

  /// Category breakdown for pie charts
  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (var tx in _transactions) {
      if (map.containsKey(tx.category)) {
        map[tx.category] = map[tx.category]! + tx.amount;
      } else {
        map[tx.category] = tx.amount;
      }
    }
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  /// Projected end of month spending
  double get projectedEndOfMonth {
    final now = DateTime.now();
    if (totalSpentMonth == 0 || now.day == 0) return 0.0;
    final dailyAverage = totalSpentMonth / now.day;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return dailyAverage * lastDay;
  }

  /// Month over month trend
  double? get monthOverMonthTrend {
    final now = DateTime.now();
    final prevDate = DateTime(now.year, now.month - 1);
    final currentTotal = totalSpentMonth;

    final prevTotal = _transactions
        .where((tx) => tx.date.year == prevDate.year && tx.date.month == prevDate.month)
        .fold(0.0, (sum, item) => sum + item.amount);

    if (prevTotal == 0) return null;
    return (currentTotal - prevTotal) / prevTotal;
  }

  // --- ACTIONS ---

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;

    try {
      _transactions = await DatabaseHelper.instance.readAllTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      
      _goals = await DatabaseHelper.instance.getGoals();
      
      // Load budget settings from database
      final budgetSettings = await DatabaseHelper.instance.getAllBudgetSettings();
      if (budgetSettings['monthly_budget'] != null) {
        _monthlyBudget = budgetSettings['monthly_budget']!;
      }
      if (budgetSettings['daily_budget'] != null) {
        _dailyBudget = budgetSettings['daily_budget'];
      }
      
      debugPrint("📊 Loaded budget settings: monthly=$_monthlyBudget, daily=$_dailyBudget");
    } catch (e) {
      debugPrint("Error loading data: $e");
      _error = "Failed to load data. Please restart.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    try {
      final id = await DatabaseHelper.instance.create(tx);
      final newTx = tx.copyWith(id: id);
      _transactions.insert(0, newTx);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to add transaction: $e");
      _error = "Could not save transaction.";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    final int index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    final TransactionModel deletedItem = _transactions[index];

    try {
      _transactions.removeAt(index);
      notifyListeners();
      await DatabaseHelper.instance.delete(id);
    } catch (e) {
      debugPrint("Failed to delete transaction: $e");
      _transactions.insert(index, deletedItem);
      notifyListeners();
    }
  }

  // --- GOAL ACTIONS ---

  Future<void> addGoal(GoalModel goal) async {
    try {
      await DatabaseHelper.instance.addGoal(goal);
      await loadData(); // Reload to update UI
    } catch (e) {
      debugPrint("Failed to add goal: $e");
      _error = "Could not save goal.";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    try {
      await DatabaseHelper.instance.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to update goal: $e");
      _error = "Could not update goal.";
      notifyListeners();
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await DatabaseHelper.instance.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to delete goal: $e");
      _error = "Could not delete goal.";
      notifyListeners();
    }
  }

  Future<void> addToGoal(int goalId, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    
    final updatedGoal = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
      isCompleted: goal.savedAmount + amount >= goal.targetAmount,
    );
    
    await updateGoal(updatedGoal);
  }

  // --- BUDGET ACTIONS ---

  Future<void> setMonthlyBudget(double newBudget) async {
    _monthlyBudget = newBudget;
    notifyListeners();
    // Persist to database
    try {
      await DatabaseHelper.instance.saveBudgetSetting('monthly_budget', newBudget);
      debugPrint("💾 Saved monthly budget: $newBudget");
    } catch (e) {
      debugPrint("Failed to save monthly budget: $e");
    }
  }

  Future<void> setDailyBudget(double? newBudget) async {
    _dailyBudget = newBudget;
    notifyListeners();
    // Persist to database
    try {
      if (newBudget != null) {
        await DatabaseHelper.instance.saveBudgetSetting('daily_budget', newBudget);
        debugPrint("💾 Saved daily budget: $newBudget");
      }
    } catch (e) {
      debugPrint("Failed to save daily budget: $e");
    }
  }

  Future<void> clearDailyBudget() async {
    _dailyBudget = null;
    notifyListeners();
    // Remove from database
    try {
      await DatabaseHelper.instance.deleteBudgetSetting('daily_budget');
      debugPrint("🗑️ Cleared daily budget from database");
    } catch (e) {
      debugPrint("Failed to clear daily budget: $e");
    }
  }

  // --- IMPORT/EXPORT ACTIONS ---

  /// Import transactions from a CSV file path
  /// Returns the number of successfully imported transactions
  Future<int> importTransactionsFromCSV(String filePath) async {
    try {
      final csvContent = await File(filePath).readAsString();
      final transactions = ImportExportHelper.parseCSVContent(csvContent);
      return await _saveImportedTransactions(transactions);
    } catch (e) {
      debugPrint("Failed to import transactions: $e");
      _error = "Failed to import transactions: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  /// Import transactions from CSV bytes (for file_picker)
  /// Returns the number of successfully imported transactions
  Future<int> importTransactionsFromBytes(String csvContent) async {
    try {
      final transactions = ImportExportHelper.parseCSVContent(csvContent);
      return await _saveImportedTransactions(transactions);
    } catch (e) {
      debugPrint("Failed to import transactions: $e");
      _error = "Failed to import transactions: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  /// Helper to save imported transactions
  Future<int> _saveImportedTransactions(List<TransactionModel> transactions) async {
    for (var tx in transactions) {
      final id = await DatabaseHelper.instance.create(tx);
      final newTx = tx.copyWith(id: id);
      _transactions.insert(0, newTx);
    }
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    
    debugPrint("📥 Imported ${transactions.length} transactions");
    return transactions.length;
  }

  /// Export transactions to CSV format
  /// Returns the CSV string content
  String exportTransactionsToCSV() {
    return ImportExportHelper.exportToCSV(_transactions);
  }
}
