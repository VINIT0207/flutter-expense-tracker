import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// For Glassmorphism

// --- LOGIC IMPORTS ---
import '../logic/finance_provider.dart';
import '../logic/decision_engine.dart';
import '../models/transaction.dart';
import '../models/goal.dart';

// --- WIDGET IMPORTS ---
// We'll reuse the category icon logic if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation controller for the floating action button scale effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accessing the provider to get real-time financial data
    final provider = Provider.of<FinanceProvider>(context);

    // Calculating financial health status
    final dailyLimit = DecisionEngine.getDailySafeLimit(
      provider.totalSpentMonth,
      provider.monthlyBudget,
      customDailyBudget: provider.dailyBudget,
      dailySavingsRequired: provider.totalDailySavingsRequired,
    );
    final status = DecisionEngine.getStatus(provider.spentToday, dailyLimit);

    return Scaffold(
      // Background color is handled by the Theme in main.dart
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. THE SMART HEADER (App Bar)
              _buildSliverAppBar(context, status, dailyLimit, provider.spentToday, provider),

              // 2. DASHBOARD WIDGETS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildSectionHeader("Financial Pulse"),
                      const SizedBox(height: 12),
                      _buildPulseCards(context),
                      const SizedBox(height: 24),
                      // Savings Goals Section
                      _buildSavingsGoalsSection(provider),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader("Recent Activity"),
                          TextButton(
                            onPressed: () {
                              // Navigate to full history (future feature)
                            },
                            child: const Text("View All", style: TextStyle(fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // 3. TRANSACTION LIST
              _buildTransactionList(provider),

              // Bottom Padding to clear the FAB
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // LOADING OVERLAY (Shown only when database is initializing)
          if (provider.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),

      // 4. FLOATING ACTION BUTTON
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/add'),
          label: const Text("Add Expense"),
          icon: const Icon(Icons.add_circle_outline),
          elevation: 4,
          highlightElevation: 8,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSliverAppBar(BuildContext context, Map status, double limit, double spent, FinanceProvider provider) {
    // Determine gradient based on status color
    final Color statusColor = Color(status['color']);
    final Color darkBg = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      expandedHeight: 260.0,
      floating: false,
      pinned: true,
      stretch: true, // Allows pulling down to stretch the header
      backgroundColor: darkBg,
      elevation: 0,

      // The content that disappears/shrinks
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withAlpha(204),
                    darkBg,
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),

            // Decorative Circles (Glassmorphism)
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(13),
                ),
              ),
            ),

            // Main Info Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            status['status'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SPENT TODAY",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        // Show budget indicator
                        if (provider.dailyBudget != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 12, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  "Daily: ₹${provider.dailyBudget!.toStringAsFixed(0)}",
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showBudgetDialog(context, provider),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "₹${spent.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "/ ₹${limit.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status['message'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky Title (Visible when collapsed)
      title: Text(
        "Dashboard",
        style: TextStyle(color: Colors.white.withAlpha(0)), // Hidden initially
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Set Budget", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Daily Budget", style: TextStyle(color: Colors.white)),
              subtitle: provider.dailyBudget != null
                  ? Text("₹${provider.dailyBudget!.toStringAsFixed(0)}/day", style: const TextStyle(color: Colors.white54))
                  : const Text("Not set (uses monthly)", style: TextStyle(color: Colors.white54)),
              leading: const Icon(Icons.today, color: Color(0xFF6366F1)),
              onTap: () {
                Navigator.pop(ctx);
                _showNumberInputDialog(
                  context,
                  title: "Daily Budget",
                  initialValue: provider.dailyBudget?.toString() ?? "",
                  onSave: (value) async {
                    final amount = double.tryParse(value);
                    if (amount != null && amount > 0) {
                      await Provider.of<FinanceProvider>(context, listen: false).setDailyBudget(amount);
                    }
                  },
                );
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              title: const Text("Monthly Budget", style: TextStyle(color: Colors.white)),
              subtitle: Text("₹${provider.monthlyBudget.toStringAsFixed(0)}/month", style: const TextStyle(color: Colors.white54)),
              leading: const Icon(Icons.calendar_month, color: Color(0xFF10B981)),
              onTap: () {
                Navigator.pop(ctx);
                _showNumberInputDialog(
                  context,
                  title: "Monthly Budget",
                  initialValue: provider.monthlyBudget.toString(),
                  onSave: (value) async {
                    final amount = double.tryParse(value);
                    if (amount != null && amount > 0) {
                      await Provider.of<FinanceProvider>(context, listen: false).setMonthlyBudget(amount);
                    }
                  },
                );
              },
            ),
            if (provider.dailyBudget != null) ...[
              const Divider(color: Colors.white10),
              ListTile(
                title: const Text("Clear Daily Budget", style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Provider.of<FinanceProvider>(context, listen: false).clearDailyBudget();
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showNumberInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter amount",
            hintStyle: TextStyle(color: Colors.white38),
            prefixText: "₹ ",
            prefixStyle: TextStyle(color: Colors.white54),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSave(controller.text);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPulseCards(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: "Analysis",
              subtitle: "View Charts",
              icon: Icons.pie_chart_outline,
              color: const Color(0xFF8B5CF6), // Violet
              onTap: () => Navigator.pushNamed(context, '/advanced'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionCard(
              title: "History",
              subtitle: "All Records",
              icon: Icons.history,
              color: const Color(0xFF10B981), // Emerald
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsSection(FinanceProvider provider) {
    final activeGoals = provider.goals.where((g) => !g.isCompleted).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader("Savings Goals"),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/add-goal'),
              child: const Text("+ Add Goal", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.totalDailySavingsRequired > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6366F1).withAlpha(51), const Color(0xFF8B5CF6).withAlpha(26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withAlpha(51)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Savings Required",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      "₹${provider.totalDailySavingsRequired.toStringAsFixed(0)}/day",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (activeGoals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings_outlined, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No Savings Goals",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Set goals to save for the future",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/add-goal'),
                  child: const Text("Create"),
                ),
              ],
            ),
          )
        else
          ...activeGoals.take(3).map((goal) => _GoalCard(goal: goal)),
      ],
    );
  }

  Widget _buildTransactionList(FinanceProvider provider) {
    if (provider.transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.white10),
              SizedBox(height: 16),
              Text(
                "No transactions yet",
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              Text(
                "Tap + to add your first expense",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final tx = provider.transactions[index];
          return _TransactionTile(tx: tx);
        },
        childCount: provider.transactions.length,
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(tx.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("Delete Transaction?"),
            content: Text("Are you sure you want to remove '${tx.category}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        Provider.of<FinanceProvider>(context, listen: false).deleteTransaction(tx.id!);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tx.isEssential
                  ? Colors.blue.withAlpha(26)
                  : Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.isEssential ? Icons.verified_user_outlined : Icons.shopping_bag_outlined,
              color: tx.isEssential ? Colors.blueAccent : Colors.orangeAccent,
              size: 24,
            ),
          ),
          title: Text(
            tx.category,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            DateFormat('MMM d • h:mm a').format(tx.date),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: Text(
            "- ₹${tx.amount.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// Goal Card Widget
class _GoalCard extends StatelessWidget {
  final GoalModel goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onLongPress: () => _showGoalOptionsDialog(context, goal),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${goal.daysRemaining} days left • ₹${goal.dailySavingsNeeded.toStringAsFixed(0)}/day needed",
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${goal.savedAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${(goal.progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Add money button
                GestureDetector(
                  onTap: () => _showAddMoneyDialog(context, goal),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF10B981), size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 6,
                backgroundColor: Colors.white.withAlpha(26),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, GoalModel goal) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Add to ${goal.title}", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter amount",
            hintStyle: TextStyle(color: Colors.white38),
            prefixText: "₹ ",
            prefixStyle: TextStyle(color: Colors.white54),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Provider.of<FinanceProvider>(context, listen: false).addToGoal(goal.id!, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showGoalOptionsDialog(BuildContext context, GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(goal.title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Add Money", style: TextStyle(color: Colors.white)),
              leading: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMoneyDialog(context, goal);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              title: const Text("Delete Goal", style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context, goal);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Goal?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete '${goal.title}'? This action cannot be undone.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteGoal(goal.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
