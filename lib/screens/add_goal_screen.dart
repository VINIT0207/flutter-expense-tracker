import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../logic/finance_provider.dart';
import '../models/goal.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _savedAmountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedFrequency = 'Monthly';

  final List<String> _frequencies = ['Weekly', 'Monthly', 'Yearly'];

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _submitGoal() {
    final title = _titleController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text);
    final savedAmount = double.tryParse(_savedAmountController.text) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a goal title")),
      );
      return;
    }

    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid target amount")),
      );
      return;
    }

    if (savedAmount > targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved amount cannot exceed target amount")),
      );
      return;
    }

    final goal = GoalModel(
      title: title,
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      targetDate: _targetDate,
      isCompleted: savedAmount >= targetAmount,
    );

    Provider.of<FinanceProvider>(context, listen: false).addGoal(goal);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Savings Goal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Title
            const Text(
              "What are you saving for?",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: "e.g., New Phone, Vacation, Emergency Fund",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 24),

            // Target Amount
            const Text(
              "Target Amount",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(color: Colors.white54, fontSize: 18),
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 24),

            // Initial Saved Amount (Optional)
            const Text(
              "Already Saved (Optional)",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _savedAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(color: Colors.white54, fontSize: 18),
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 24),

            // Target Date
            const Text(
              "Target Date",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: ListTile(
                onTap: _selectDate,
                leading: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                title: Text(
                  DateFormat('MMMM d, yyyy').format(_targetDate),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "${_targetDate.difference(DateTime.now()).inDays} days from now",
                  style: const TextStyle(color: Colors.white38),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),

            // Savings Frequency
            const Text(
              "Savings Frequency",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: Column(
                children: _frequencies.map((freq) {
                  final isSelected = _selectedFrequency == freq;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFrequency = freq;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: freq != _frequencies.last
                              ? BorderSide(color: Colors.white.withAlpha(13))
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              freq,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white54,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: Color(0xFF6366F1)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1).withAlpha(51), const Color(0xFF8B5CF6).withAlpha(26)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Text(
                        "Goal Summary",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow("Target", "₹${_targetAmountController.text.isEmpty ? '0' : _targetAmountController.text}"),
                  const SizedBox(height: 8),
                  _buildSummaryRow("Target Date", DateFormat('MMM d, yyyy').format(_targetDate)),
                  const SizedBox(height: 8),
                  _buildSummaryRow("Duration", "${_targetDate.difference(DateTime.now()).inDays} days"),
                  const SizedBox(height: 16),
                  if (_targetAmountController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Daily Savings Required",
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              Text(
                                "₹${_calculateDailySavings().toStringAsFixed(0)}/day",
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitGoal,
                child: const Text(
                  "Create Goal",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDailySavings() {
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    if (targetAmount <= 0) return 0;
    final daysRemaining = _targetDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return targetAmount;
    return targetAmount / daysRemaining;
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54),
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}

