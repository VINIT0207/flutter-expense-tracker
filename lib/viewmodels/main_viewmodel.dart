import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../data/finance_repository.dart';
import '../utils/import_export_helper.dart';
import '../utils/notification_service.dart';

/// Manages the application state, handles data interactions,
/// and provides real-time financial analytics.
class MainViewModel with ChangeNotifier {
  final FinanceRepository _repository;

  MainViewModel(this._repository);

  // --- STATE ---
  List<TransactionModel> _transactions = [];
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;
  double _monthlyBudget = 15000.0;
  double? _dailyBudget;
  DateTime? _lastSavingsDate;

  // --- GETTERS ---
  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get monthlyBudget => _monthlyBudget;
  double? get dailyBudget => _dailyBudget;
  DateTime? get lastSavingsDate => _lastSavingsDate;

  bool get hasSavingsLoggedToday {
    if (_lastSavingsDate == null) return false;
    final now = DateTime.now();
    return _lastSavingsDate!.year == now.year &&
        _lastSavingsDate!.month == now.month &&
        _lastSavingsDate!.day == now.day;
  }

  // --- SMART CALCULATIONS ---

  double get totalDailySavingsRequired {
    double total = 0;
    for (var goal in _goals) {
      if (!goal.isCompleted && goal.savedAmount < goal.targetAmount) {
        total += goal.dailySavingsNeeded;
      }
    }
    return total;
  }

  double get effectiveMonthlyBudget {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDay - now.day + 1;
    
    return _monthlyBudget - (totalDailySavingsRequired * daysRemaining);
  }

  double get totalSpentMonth {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get spentToday {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get budgetProgress => totalSpentMonth / (_monthlyBudget > 0 ? _monthlyBudget : 1);

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

  double get projectedEndOfMonth {
    final now = DateTime.now();
    if (totalSpentMonth == 0 || now.day == 0) return 0.0;
    final dailyAverage = totalSpentMonth / now.day;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return dailyAverage * lastDay;
  }

  double get projectedMonthlySpend {
    final now = DateTime.now();
    final daysPassed = now.day;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    if (daysPassed == 0) return 0;
    final dailyAverage = totalSpentMonth / daysPassed;
    return dailyAverage * lastDay;
  }

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
      _transactions = await _repository.getTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      
      _goals = await _repository.getGoals();
      
      final savedMonthly = await _repository.getBudgetSetting('monthly_budget');
      if (savedMonthly != null) _monthlyBudget = savedMonthly;
      
      final savedDaily = await _repository.getBudgetSetting('daily_budget');
      if (savedDaily != null) _dailyBudget = savedDaily;

      final lastSavingsMillis = await _repository.getBudgetSetting('last_savings_date_millis');
      if (lastSavingsMillis != null) {
        _lastSavingsDate = DateTime.fromMillisecondsSinceEpoch(lastSavingsMillis.toInt());
      }
      
      debugPrint("📊 Loaded budget settings: monthly=$_monthlyBudget, daily=$_dailyBudget, lastSavings=$_lastSavingsDate");
      NotificationService().scheduleHourlyReminder(recentTxs: _transactions);
      NotificationService().scheduleGoalNotifications(_goals, hasSavingsLoggedToday: hasSavingsLoggedToday);
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
      await _repository.addTransaction(tx);
      // Reload to get generated ID or just reload all
      await loadData();
      NotificationService().scheduleHourlyReminder(recentTxs: _transactions);
    } catch (e) {
      debugPrint("Failed to add transaction: $e");
      _error = "Could not save transaction.";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadData();
    } catch (e) {
      debugPrint("Failed to delete transaction: $e");
      _error = "Could not delete transaction.";
      notifyListeners();
    }
  }

  // --- GOAL ACTIONS ---

  Future<void> addGoal(GoalModel goal) async {
    try {
      await _repository.addGoal(goal);
      await loadData(); // Reload to update UI
      NotificationService().scheduleGoalNotifications(_goals, hasSavingsLoggedToday: hasSavingsLoggedToday);
    } catch (e) {
      debugPrint("Failed to add goal: $e");
      _error = "Could not save goal.";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    try {
      await _repository.updateGoal(goal);
      await loadData();
      NotificationService().scheduleGoalNotifications(_goals, hasSavingsLoggedToday: hasSavingsLoggedToday);
    } catch (e) {
      debugPrint("Failed to update goal: $e");
      _error = "Could not update goal.";
      notifyListeners();
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _repository.deleteGoal(id);
      await loadData();
      NotificationService().scheduleGoalNotifications(_goals, hasSavingsLoggedToday: hasSavingsLoggedToday);
    } catch (e) {
      debugPrint("Failed to delete goal: $e");
      _error = "Could not delete goal.";
      notifyListeners();
    }
  }

  Future<void> addToGoal(int goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;
    
    final goal = _goals[index];
    final isNowCompleted = goal.savedAmount + amount >= goal.targetAmount;
    final updatedGoal = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
      isCompleted: isNowCompleted,
    );
    
    _lastSavingsDate = DateTime.now();
    await _repository.saveBudgetSetting('last_savings_date_millis', _lastSavingsDate!.millisecondsSinceEpoch.toDouble());

    await updateGoal(updatedGoal);
    await NotificationService().scheduleGoalNotifications(_goals, hasSavingsLoggedToday: true);

    if (isNowCompleted) {
      NotificationService().showGoalAlert(
        "🎉 Goal Achieved!",
        "Congratulations! You've successfully achieved your goal '${goal.title}' of ₹${goal.targetAmount.toStringAsFixed(0)}!",
      );
    }
  }

  // --- BUDGET ACTIONS ---

  Future<void> setMonthlyBudget(double newBudget) async {
    _monthlyBudget = newBudget;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    _dailyBudget = newBudget / daysInMonth; // Align daily budget dynamically
    notifyListeners();
    try {
      await _repository.saveBudgetSetting('monthly_budget', _monthlyBudget);
      await _repository.saveBudgetSetting('daily_budget', _dailyBudget!);
      debugPrint("💾 Saved monthly budget: $_monthlyBudget, daily: $_dailyBudget");
    } catch (e) {
      debugPrint("Failed to save budget settings: $e");
    }
  }

  Future<void> setDailyBudget(double? newBudget) async {
    _dailyBudget = newBudget;
    if (newBudget != null) {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      _monthlyBudget = newBudget * daysInMonth; // Align monthly budget dynamically
    }
    notifyListeners();
    try {
      if (newBudget != null) {
        await _repository.saveBudgetSetting('daily_budget', _dailyBudget!);
        await _repository.saveBudgetSetting('monthly_budget', _monthlyBudget);
        debugPrint("💾 Saved daily budget: $_dailyBudget, monthly: $_monthlyBudget");
      }
    } catch (e) {
      debugPrint("Failed to save budget settings: $e");
    }
  }

  Future<void> clearDailyBudget() async {
    _dailyBudget = null;
    notifyListeners();
    // DatabaseHelper requires adding a delete method, 
    // but we can just save it as 0 or ignore it.
    // For now, skip DB deletion if not implemented in Repo, or implement it in Repo.
  }

  // --- IMPORT/EXPORT ACTIONS ---

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

  Future<int> _saveImportedTransactions(List<TransactionModel> txs) async {
    for (var tx in txs) {
      await _repository.addTransaction(tx);
    }
    await loadData();
    debugPrint("📥 Imported ${txs.length} transactions");
    return txs.length;
  }

  String exportTransactionsToCSV() {
    return ImportExportHelper.exportToCSV(_transactions);
  }
}
