import '../services/local_ai_service.dart';
import '../data/finance_repository.dart';

class SlmResponse {
  final String reply;
  final String? navigationRoute;

  SlmResponse({required this.reply, this.navigationRoute});
}

class SlmController {
  final LocalAiService aiService;
  final FinanceRepository _repository;

  SlmController(this.aiService, this._repository);

  Future<SlmResponse> processUserMessage(
      String userInput, double monthlyBudget) async {
    final trimmedInput = userInput.trim().toLowerCase();

    if (!aiService.isInitialized) {
      return SlmResponse(
        reply:
            "I'm initializing my neural engine... Please ask me again in just a moment! ⏳",
      );
    }

    // 1. Gather Complete Live Financial Context from SQLite Database
    final allTxs = await _repository.getTransactions();
    final allGoals = await _repository.getGoals();
    final now = DateTime.now();
    final currentMonthTxs = allTxs
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final totalSpentMonth =
        currentMonthTxs.fold(0.0, (sum, t) => sum + t.amount);
    final remainingBudget = monthlyBudget - totalSpentMonth;
    final spentPercent = monthlyBudget > 0
        ? ((totalSpentMonth / monthlyBudget) * 100)
            .clamp(0, 999)
            .toStringAsFixed(1)
        : "0";
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day.clamp(1, 31);
    final daysLeft = (daysInMonth - now.day + 1).clamp(1, 31);
    final avgDailySpent = (totalSpentMonth / daysPassed);
    final safeDailyLimit =
        remainingBudget > 0 ? (remainingBudget / daysLeft) : 0.0;
    final savingsBuffer = (remainingBudget * 0.20)
        .clamp(0.0, remainingBudget > 0 ? remainingBudget : 0.0);
    final savingsDailyPace = remainingBudget > savingsBuffer
        ? ((remainingBudget - savingsBuffer) / daysLeft)
        : safeDailyLimit;

    // Essential vs Non-essential breakdown
    double essentialTotal = 0.0;
    double nonEssentialTotal = 0.0;
    for (final t in currentMonthTxs) {
      if (t.isEssential) {
        essentialTotal += t.amount;
      } else {
        nonEssentialTotal += t.amount;
      }
    }

    // Category breakdowns
    final categoryTotals = <String, double>{};
    for (final t in currentMonthTxs) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0.0) + t.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catBreakdownStr = sortedCategories.isNotEmpty
        ? sortedCategories.map((e) {
            final pct = totalSpentMonth > 0
                ? ((e.value / totalSpentMonth) * 100).toStringAsFixed(0)
                : "0";
            return "${e.key}: ₹${e.value.toStringAsFixed(0)} ($pct%)";
          }).join(", ")
        : "None recorded yet";

    // Recent transactions list
    final recentTxs = List.of(currentMonthTxs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTxsStr = recentTxs.isNotEmpty
        ? recentTxs
            .take(6)
            .map((t) =>
                "${t.title} (₹${t.amount.toStringAsFixed(0)}, ${t.category}${t.isEssential ? ', Essential' : ', Want'})")
            .join("; ")
        : "None";

    // Active goals
    final activeGoals = allGoals.where((g) => !g.isCompleted).toList();
    final goalsStr = activeGoals.isNotEmpty
        ? activeGoals
            .map((g) =>
                "${g.title}: ₹${g.savedAmount.toStringAsFixed(0)} / ₹${g.targetAmount.toStringAsFixed(0)}")
            .join("; ")
        : "No active goals";

    // 2. Full Rich Financial Context (We can afford this now with 16k token limit)
    final liveContext = "Monthly Budget: ₹${monthlyBudget.toStringAsFixed(0)}\n"
        "Total Outflow: ₹${totalSpentMonth.toStringAsFixed(0)} across ${currentMonthTxs.length} transactions ($spentPercent% used)\n"
        "Remaining Balance: ₹${remainingBudget.toStringAsFixed(0)}\n"
        "Essential Spending: ₹${essentialTotal.toStringAsFixed(0)}, Non-Essential (Wants): ₹${nonEssentialTotal.toStringAsFixed(0)}\n"
        "Timeline: $daysPassed days passed, $daysLeft days remaining in month\n"
        "Daily Spending Burn Rate: ₹${avgDailySpent.toStringAsFixed(0)}/day\n"
        "Safe Daily Spending Ceiling: ₹${safeDailyLimit.toStringAsFixed(0)}/day\n"
        "Recommended Daily Pace for ₹${savingsBuffer.toStringAsFixed(0)} Savings Buffer: ₹${savingsDailyPace.toStringAsFixed(0)}/day\n"
        "Category Breakdown: $catBreakdownStr\n"
        "Recent Purchases: $recentTxsStr\n"
        "Active Goals: $goalsStr";

    // 3. Navigation check
    String? navRoute;
    if (_isExplicitNavigation(trimmedInput)) {
      navRoute = _resolveNavigationRoute(trimmedInput);
    }

    // 4. Generate AI Response
    final rawAiResponse = await aiService.generateChat(
      userInput,
      liveContext: liveContext,
    );

    if (rawAiResponse != null && rawAiResponse.trim().isNotEmpty) {
      String fullText = rawAiResponse.trim();

      // Check navigation tags
      if (fullText.contains("[NAVIGATE:")) {
        final reg = RegExp(r'\[NAVIGATE:\s*([\w_/-]+)\]');
        final match = reg.firstMatch(fullText);
        if (match != null) {
          navRoute = _resolveNavigationRoute(match.group(1) ?? "");
        }
        fullText =
            fullText.replaceAll(RegExp(r'\[NAVIGATE:[^\]]+\]'), '').trim();
      }
      fullText = fullText.replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '').trim();
      
      // Remove any markdown formatting characters (*, _, #, `)
      fullText = fullText.replaceAll(RegExp(r'[*_#`]'), '');

      return SlmResponse(reply: fullText, navigationRoute: navRoute);
    }

    return SlmResponse(
      reply:
          "You have ₹${remainingBudget.toStringAsFixed(0)} left in your monthly budget. Your safe daily spending limit for the remaining $daysLeft days is ₹${safeDailyLimit.toStringAsFixed(0)}/day.",
      navigationRoute: navRoute,
    );
  }

  bool _isExplicitNavigation(String text) {
    return text.startsWith("open ") ||
        text.startsWith("go to ") ||
        text.startsWith("take me to ") ||
        text.startsWith("navigate to ") ||
        text == "add expense" ||
        text == "add entry";
  }

  String? _resolveNavigationRoute(String text) {
    if (text.contains("add") || text.contains("expense") || text.contains("entry")) {
      return "/add";
    } else if (text.contains("dashboard") || text.contains("analytic") || text.contains("chart") || text.contains("advanced")) {
      return "/advanced";
    } else if (text.contains("goal") || text.contains("target")) {
      return "/add-goal";
    } else if (text.contains("history") || text.contains("record") || text.contains("log")) {
      return "/history";
    }
    return "/home";
  }
}
