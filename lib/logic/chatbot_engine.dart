import '../viewmodels/main_viewmodel.dart';
import 'decision_engine.dart';

/// A lightweight, offline intent-based chatbot engine.
class ChatbotEngine {
  static String getReply(String message, MainViewModel viewModel) {
    final msg = message.toLowerCase();
    
    // 1. INTENT: Greetings
    if (msg == "hi" || msg == "hello" || msg == "hey" || msg.startsWith("hi ") || msg.startsWith("hello ")) {
      final greetings = [
        "Hello there! I'm your Offline AI Advisor. I can explain how the app works, analyze your budget, or give you financial tips. How can I help?",
        "Hey! I'm your personal finance AI. Feel free to ask me how much you've spent, what your budget is, or how to use the app!",
        "Greetings! I'm ready to help you manage your money. Try asking me for 'financial advice' or 'how does this app work'."
      ];
      return greetings[DateTime.now().millisecond % greetings.length];
    }
    
    // 1.5 INTENT: How the app works
    if (_fuzzyContains(msg, "how") && (_fuzzyContains(msg, "work") || _fuzzyContains(msg, "use") || _fuzzyContains(msg, "app"))) {
      return "I'd love to explain! This app is your personal financial command center.\n\n"
             "1. 'Home': See your daily safe spending limit and log new expenses.\n"
             "2. 'Advanced Dashboard': View charts and get my AI insights on your spending velocity.\n"
             "3. 'Goals': Set savings targets, and I'll warn you if they are unrealistic based on your budget.\n\n"
             "You can ask me questions anytime, completely offline!";
    }

    // 2. INTENT: Advice / Optimization
    if (_fuzzyContains(msg, "advice") || _fuzzyContains(msg, "help") || _fuzzyContains(msg, "tip") || _fuzzyContains(msg, "improve") || _fuzzyContains(msg, "optimize")) {
      return MiniGPTAdvisor.generateAdvice(viewModel.transactions, viewModel.monthlyBudget);
    }
    
    // 3. INTENT: Budget / Remaining
    if (_fuzzyContains(msg, "budget", maxDistance: 2) || _fuzzyContains(msg, "left") || _fuzzyContains(msg, "remaining") || _fuzzyContains(msg, "safe")) {
      final safeLimit = DecisionEngine.getDailySafeLimit(
        viewModel.totalSpentMonth, 
        viewModel.monthlyBudget, 
        customDailyBudget: viewModel.dailyBudget, 
        dailySavingsRequired: viewModel.totalDailySavingsRequired
      );
      double remaining = viewModel.monthlyBudget - viewModel.totalSpentMonth;
      if (remaining < 0) {
        return "You have exceeded your monthly budget by ₹${remaining.abs().toStringAsFixed(0)}.";
      }
      return "You have ₹${remaining.toStringAsFixed(0)} remaining for the month. Your safe daily spending limit is ₹${safeLimit.toStringAsFixed(0)}.";
    }

    // 4. INTENT: Category Specific Spending
    // Dynamically check against user's actual categories
    List<String> knownCategories = viewModel.transactions.map((t) => t.category.toLowerCase()).toSet().toList();
    for (String cat in knownCategories) {
      if (_fuzzyContains(msg, cat, maxDistance: 2)) {
        double catTotal = viewModel.transactions
            .where((t) => t.category.toLowerCase() == cat)
            .fold(0.0, (sum, item) => sum + item.amount);
        
        // Find top transaction in this category
        var catTxs = viewModel.transactions.where((t) => t.category.toLowerCase() == cat).toList();
        catTxs.sort((a, b) => b.amount.compareTo(a.amount));
        String highest = catTxs.isNotEmpty ? "\nYour largest expense was ₹${catTxs.first.amount.toStringAsFixed(0)}." : "";

        // Capitalize first letter of category for display
        String displayCat = cat[0].toUpperCase() + cat.substring(1);
        return "You have spent ₹${catTotal.toStringAsFixed(0)} on $displayCat historically.$highest";
      }
    }

    // 5. INTENT: General Spending
    if (_fuzzyContains(msg, "spent") || _fuzzyContains(msg, "total") || _fuzzyContains(msg, "outflow") || _fuzzyContains(msg, "spend")) {
      return "You have spent ₹${viewModel.totalSpentMonth.toStringAsFixed(0)} this month, and ₹${viewModel.spentToday.toStringAsFixed(0)} today.";
    }

    // 6. INTENT: Goals / Savings
    if (_fuzzyContains(msg, "goal") || _fuzzyContains(msg, "save") || _fuzzyContains(msg, "target")) {
      if (viewModel.goals.isEmpty) {
        return "You don't have any active goals. Set one up in the Add Goal screen!";
      }
      int active = viewModel.goals.where((g) => !g.isCompleted).length;
      return "You have $active active goals. You need to save ₹${viewModel.totalDailySavingsRequired.toStringAsFixed(0)} per day to stay on track for your targets.";
    }

    // 7. FALLBACK
    final fallbacks = [
      "I might not understand that yet, but I'm great with numbers! Try asking: 'How does the app work?', 'What is my budget?', or 'Give me advice.'",
      "I'm a lightweight AI, so I stick strictly to finances! Ask me about your 'Food' spending, your active 'goals', or your 'remaining budget'.",
      "Hmm, I didn't quite catch that. But I can tell you all about your money! Try asking for 'financial advice'."
    ];
    return fallbacks[DateTime.now().millisecond % fallbacks.length];
  }

  /// Calculates the Levenshtein distance between two words to detect typos.
  static int _levenshtein(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.filled(b.length + 1, 0);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        int minCost = v1[j] + 1;
        if (v0[j + 1] + 1 < minCost) minCost = v0[j + 1] + 1;
        if (v0[j] + cost < minCost) minCost = v0[j] + cost;
        v1[j + 1] = minCost;
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }

  /// Checks if the sentence contains the keyword, allowing for minor typos.
  static bool _fuzzyContains(String sentence, String keyword, {int maxDistance = 1}) {
    if (sentence.contains(keyword)) return true;
    
    // Split sentence into words, removing punctuation
    List<String> words = sentence.replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    for (String word in words) {
      // Only check words of similar length to avoid unnecessary computation
      if (word.length >= keyword.length - 1 && word.length <= keyword.length + 1) {
        if (_levenshtein(word, keyword) <= maxDistance) {
          return true;
        }
      }
    }
    return false;
  }
}
