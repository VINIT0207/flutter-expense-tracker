import '../models/transaction.dart';

/// A pure logic class responsible for financial algorithms and analysis.
/// It takes raw data and returns actionable insights using
/// institutional-grade algorithms.
class DecisionEngine {

  /// Calculates the "Safe-to-Spend" limit for the current day.
  ///
  /// Advanced Logic: 
  /// - If customDailyBudget is provided, it will be returned directly.
  /// - Otherwise, calculates from monthly budget with Dynamic Safety Buffer.
  /// - CRITICAL: Subtracts dailySavingsRequired to reserve money for goals.
  /// - Early month (Day 1-10): 15% buffer (be stricter).
  /// - Mid month (Day 11-20): 10% buffer.
  /// - Late month (Day 21+): 5% buffer (allow more freedom).
  static double getDailySafeLimit(
    double currentTotalSpent,
    double monthlyBudget, {
    double? customDailyBudget,
    double dailySavingsRequired = 0,
  }) {
    // If a custom daily budget is set, use it directly
    if (customDailyBudget != null && customDailyBudget > 0) {
      return customDailyBudget;
    }

    final now = DateTime.now();

    // Calculate days remaining in the month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysRemaining = lastDayOfMonth.day - now.day + 1;

    // Remaining budget for the month
    final remainingBudget = monthlyBudget - currentTotalSpent;
    
    if (remainingBudget <= 0) return 0.0;

    // Calculate how much we need to reserve for goals this month
    final monthlySavingsReserve = dailySavingsRequired * daysRemaining;
    
    // Remaining after reserving for goals
    final availableForSpending = remainingBudget - monthlySavingsReserve;
    
    if (availableForSpending <= 0) return 0.0;

    // Dynamic Buffer Logic
    double safetyBuffer = 0.10; // Default 10%
    if (now.day <= 10) {
      safetyBuffer = 0.15;
    } else if (now.day > 20) safetyBuffer = 0.05;

    final safeBudget = availableForSpending * (1.0 - safetyBuffer);

    return (safeBudget / daysRemaining).clamp(0, double.infinity);
  }

  /// Returns UI status configuration based on today's spending vs limit.
  static Map<String, dynamic> getStatus(double spentToday, double safeLimit) {
    if (safeLimit <= 0) {
      return {
        'status': 'CRITICAL',
        'message': 'Budget depleted. Zero spending mode activated.',
        'color': 0xFFEF4444,
      };
    }

    if (spentToday > safeLimit) {
      final overshot = (spentToday - safeLimit).toStringAsFixed(0);
      return {
        'status': 'OVER LIMIT',
        'message': 'Exceeded safe limit by ₹$overshot. Halt spending.',
        'color': 0xFFF59E0B,
      };
    }

    if (spentToday > safeLimit * 0.85) {
      return {
        'status': 'CAUTION',
        'message': 'Approaching limit. Defer non-essential purchases.',
        'color': 0xFF3B82F6,
      };
    }

    return {
      'status': 'SAFE',
      'message': 'On track. You can afford a small treat.',
      'color': 0xFF10B981,
    };
  }

  /// Analyzes adherence to the 50/30/20 Rule.
  static Map<String, dynamic> analyze50_30_20(List<TransactionModel> txs, double monthlyBudget) {
    double needs = 0;
    double wants = 0;

    for (var tx in txs) {
      if (tx.isEssential) {
        needs += tx.amount;
      } else {
        wants += tx.amount;
      }
    }

    double totalSpent = needs + wants;
    double savings = monthlyBudget - totalSpent;
    if (savings < 0) savings = 0;

    double needsPct = (needs / monthlyBudget) * 100;
    double wantsPct = (wants / monthlyBudget) * 100;
    double savingsPct = (savings / monthlyBudget) * 100;

    String advice = "Balanced.";
    if (needsPct > 60) {
      advice = "Needs are too high. Review fixed costs.";
    } else if (wantsPct > 35) advice = "Discretionary spending is eating into savings.";
    else if (savingsPct < 15) advice = "Savings rate is critical. Aim for 20%.";

    return {
      'needs': {'amount': needs, 'percent': needsPct, 'target': 50},
      'wants': {'amount': wants, 'percent': wantsPct, 'target': 30},
      'savings': {'amount': savings, 'percent': savingsPct, 'target': 20},
      'advice': advice,
    };
  }

  /// Calculates "Runway": How many days you could survive on a specific balance
  static int calculateRunway(double currentBalance, List<TransactionModel> txs) {
    if (txs.isEmpty) return 0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    double essentialSpend30Days = txs
        .where((t) => t.isEssential && t.date.isAfter(thirtyDaysAgo))
        .fold(0, (sum, t) => sum + t.amount);

    if (essentialSpend30Days == 0) return 999;

    double dailyBurnRate = essentialSpend30Days / 30;
    return (currentBalance / dailyBurnRate).floor();
  }

  /// Generates smart insights from transaction history
  static List<String> generateInsights(List<TransactionModel> txs) {
    if (txs.isEmpty) return ["Start tracking to see AI insights."];

    List<String> insights = [];

    // Weekend Spike Detection
    double weekendSpend = 0;
    int weekendCount = 0;
    double weekdaySpend = 0;
    int weekdayCount = 0;

    for (var t in txs) {
      if (t.date.weekday >= 6) {
        weekendSpend += t.amount;
        weekendCount++;
      } else {
        weekdaySpend += t.amount;
        weekdayCount++;
      }
    }
    double avgWeekend = weekendCount > 0 ? weekendSpend / weekendCount : 0;
    double avgWeekday = weekdayCount > 0 ? weekdaySpend / weekdayCount : 0;

    if (avgWeekend > avgWeekday * 1.8) {
      insights.add("📊 Weekend spending is ${(avgWeekend/avgWeekday).toStringAsFixed(1)}x higher than weekdays.");
    }

    // Spending Velocity
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    double thisWeek = txs
        .where((t) => t.date.isAfter(sevenDaysAgo))
        .fold(0, (sum, t) => sum + t.amount);

    double lastWeek = txs
        .where((t) => t.date.isBefore(sevenDaysAgo) && t.date.isAfter(fourteenDaysAgo))
        .fold(0, (sum, t) => sum + t.amount);

    if (lastWeek > 0) {
      double velocity = ((thisWeek - lastWeek) / lastWeek) * 100;
      if (velocity > 20) {
        insights.add("⚠️ Spending accelerated by ${velocity.toStringAsFixed(0)}% this week.");
      } else if (velocity < -20) {
        insights.add("✅ Spending decelerated by ${velocity.abs().toStringAsFixed(0)}% compared to last week.");
      }
    }

    // Category Domination
    Map<String, double> catTotals = {};
    double total = 0;
    for(var t in txs) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
      total += t.amount;
    }

    if (total > 0) {
      var topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      if ((topCat.value / total) > 0.4) {
        insights.add("ℹ️ '${topCat.key}' accounts for ${(topCat.value/total * 100).toStringAsFixed(0)}% of total outflow.");
      }
    }

    return insights;
  }
}

