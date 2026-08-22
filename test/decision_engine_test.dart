import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/logic/decision_engine.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/models/goal.dart';

void main() {
  group('DecisionEngine Tests', () {
    test('getDailySafeLimit returns custom budget when set', () {
      final limit = DecisionEngine.getDailySafeLimit(
        1000,
        15000,
        customDailyBudget: 750,
        dailySavingsRequired: 100,
      );
      expect(limit, 750.0);
    });

    test('getDailySafeLimit returns 0 when budget is depleted or negative', () {
      final limit = DecisionEngine.getDailySafeLimit(
        16000,
        15000,
      );
      expect(limit, 0.0);
    });

    test('getStatus categorizes spending thresholds properly', () {
      expect(DecisionEngine.getStatus(0, 0)['status'], 'CRITICAL');
      expect(DecisionEngine.getStatus(1200, 1000)['status'], 'OVER LIMIT');
      expect(DecisionEngine.getStatus(900, 1000)['status'], 'CAUTION');
      expect(DecisionEngine.getStatus(400, 1000)['status'], 'SAFE');
    });

    test('analyze50_30_20 computes correct distribution', () {
      final txs = [
        TransactionModel(
          title: 'Rent',
          category: 'Bills',
          amount: 5000,
          date: DateTime.now(),
          isEssential: true,
        ),
        TransactionModel(
          title: 'Games',
          category: 'Entertainment',
          amount: 3000,
          date: DateTime.now(),
          isEssential: false,
        ),
      ];

      final analysis = DecisionEngine.analyze50_30_20(txs, 10000);
      expect(analysis['needs']['amount'], 5000.0);
      expect(analysis['needs']['percent'], 50.0);
      expect(analysis['wants']['amount'], 3000.0);
      expect(analysis['wants']['percent'], 30.0);
      expect(analysis['savings']['amount'], 2000.0);
      expect(analysis['savings']['percent'], 20.0);
    });

    test('calculateRunway returns safe floor days', () {
      final now = DateTime.now();
      final txs = [
        TransactionModel(
          title: 'Groceries',
          category: 'Food',
          amount: 3000,
          date: now.subtract(const Duration(days: 5)),
          isEssential: true,
        ),
      ];

      final runway = DecisionEngine.calculateRunway(6000, txs);
      // Daily burn rate = 3000 / 30 = 100. Runway = 6000 / 100 = 60 days
      expect(runway, 60);
    });
  });

  group('GoalModel Tests', () {
    test('Calculates progress and daily savings accurately', () {
      final targetDate = DateTime.now().add(const Duration(days: 10));
      final goal = GoalModel(
        title: 'New Laptop',
        targetAmount: 10000,
        savedAmount: 4000,
        targetDate: targetDate,
      );

      expect(goal.remainingAmount, 6000.0);
      expect(goal.progress, 0.4);
      expect(goal.daysRemaining >= 9 && goal.daysRemaining <= 11, isTrue);
      expect(goal.dailySavingsNeeded > 0, isTrue);
    });
  });
}
