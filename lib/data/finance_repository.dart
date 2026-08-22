import '../models/transaction.dart';
import '../models/goal.dart';
import 'database_helper.dart';

class FinanceRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<TransactionModel>> getTransactions() async {
    return await _db.readAllTransactions();
  }

  Future<int> addTransaction(TransactionModel transaction) async {
    return await _db.create(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    // Assuming update exists or we don't need it. FinanceProvider didn't have updateTransaction.
    // Let's leave it or implement it if needed.
  }

  Future<void> deleteTransaction(int id) async {
    await _db.delete(id);
  }

  Future<void> clearAllTransactions() async {
    // Not implemented in provider either.
  }

  Future<List<GoalModel>> getGoals() async {
    return await _db.getGoals();
  }

  Future<void> addGoal(GoalModel goal) async {
    await _db.addGoal(goal);
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _db.updateGoal(goal);
  }

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
  }

  Future<double?> getBudgetSetting(String key) async {
    final settings = await _db.getAllBudgetSettings();
    return settings[key];
  }

  Future<void> saveBudgetSetting(String key, double value) async {
    await _db.saveBudgetSetting(key, value);
  }
}
