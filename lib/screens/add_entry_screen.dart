import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // For blur effects

// --- LOGIC IMPORTS ---
import '../logic/finance_provider.dart';
import '../models/transaction.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  String _displayAmount = "0";
  String _selectedCategory = "Food";
  IconData _selectedIcon = Icons.restaurant;
  bool _isEssential = true;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  // Animation Controller for the Category Panel
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // --- CATEGORY DATA ---
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': 0xFFEF4444},
    {'name': 'Transport', 'icon': Icons.directions_bus, 'color': 0xFFF59E0B},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': 0xFFEC4899},
    {'name': 'Entertainment', 'icon': Icons.gamepad, 'color': 0xFF8B5CF6},
    {'name': 'Bills', 'icon': Icons.receipt_long, 'color': 0xFF3B82F6},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': 0xFF10B981},
    {'name': 'Education', 'icon': Icons.school, 'color': 0xFF6366F1},
    {'name': 'Other', 'icon': Icons.category, 'color': 0xFF64748B},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- LOGIC: INPUT HANDLING ---

  void _onKeyTap(String value) {
    HapticFeedback.lightImpact(); // Pro feel
    setState(() {
      if (value == "C") {
        _displayAmount = "0";
      } else if (value == "DEL") {
        if (_displayAmount.length > 1) {
          _displayAmount = _displayAmount.substring(0, _displayAmount.length - 1);
        } else {
          _displayAmount = "0";
        }
      } else if (value == ".") {
        if (!_displayAmount.contains(".")) {
          _displayAmount += ".";
        }
      } else {
        if (_displayAmount == "0") {
          _displayAmount = value;
        } else if (_displayAmount.length < 9) { // Prevent overflow
          _displayAmount += value;
        }
      }
    });
  }

  void _submitTransaction() {
    final double? amount = double.tryParse(_displayAmount);

    if (amount == null || amount <= 0) {
      _showErrorSnackbar("Please enter a valid amount");
      return;
    }

    // Use custom title if entered, otherwise use category
    final title = _selectedCategory == 'Other' && _noteController.text.isNotEmpty
        ? _noteController.text
        : _selectedCategory;

    final newTx = TransactionModel(
      title: title,
      category: _selectedCategory,
      amount: amount,
      date: _selectedDate,
      isEssential: _isEssential,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    // Saving via Provider
    Provider.of<FinanceProvider>(context, listen: false).addTransaction(newTx);

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // We use a Stack to put the background elements behind the interface
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withAlpha(38),
              ),
            ),
          ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. APP BAR
                _buildAppBar(context),

                // 2. AMOUNT DISPLAY
                Expanded(
                  flex: 3,
                  child: _buildAmountDisplay(theme),
                ),

                // 3. META CONTROLS (Date, Note, Essential)
                _buildMetaControls(theme),

                // Custom title field for "Other" category
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedCategory == 'Other'
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: TextField(
                            controller: _noteController,
                            key: const ValueKey('otherField'),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "What is this? (e.g. Cinema, Gift)",
                              hintStyle: const TextStyle(color: Colors.white38),
                              prefixIcon: const Icon(Icons.edit, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withAlpha(13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('spacer'), height: 60),
                ),

                const SizedBox(height: 8),

                // 4. INTERACTION PANEL (Keypad + Categories)
                Expanded(
                  flex: 6,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(_slideAnimation),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildDraggableHandle(),
                          const SizedBox(height: 20),
                          _buildCategorySelector(theme),
                          const Divider(color: Colors.white10),
                          Expanded(child: _buildKeypad(theme)),
                          _buildSubmitButton(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Text(
            "New Transaction",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          // Placeholder for balance check or empty space
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "ENTER AMOUNT",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(102),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _displayAmount,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // DATE PICKER
          Expanded(
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: theme.primaryColor,
                          surface: const Color(0xFF1E293B),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateSmart(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ESSENTIAL TOGGLE
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isEssential = !_isEssential),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isEssential
                      ? theme.primaryColor.withAlpha(51)
                      : Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isEssential
                        ? theme.primaryColor.withAlpha(128)
                        : Colors.orange.withAlpha(128),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEssential ? Icons.verified : Icons.shopping_bag_outlined,
                      size: 16,
                      color: _isEssential ? theme.primaryColor : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEssential ? "Essential" : "Optional",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isEssential ? theme.primaryColor : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          final color = Color(cat['color']);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat['name'];
                _selectedIcon = cat['icon'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              width: 70,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat['icon'],
                    color: isSelected ? Colors.white : Colors.white54,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _keypadButton("1"),
                _keypadButton("2"),
                _keypadButton("3"),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _keypadButton("4"),
                _keypadButton("5"),
                _keypadButton("6"),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _keypadButton("7"),
                _keypadButton("8"),
                _keypadButton("9"),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _keypadButton(".", isSpecial: true),
                _keypadButton("0"),
                _keypadButton("DEL", isSpecial: true, icon: Icons.backspace_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadButton(String value, {bool isSpecial = false, IconData? icon}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        child: Material(
          color: isSpecial ? Colors.white.withAlpha(13) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _onKeyTap(value),
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withAlpha(26),
            highlightColor: Colors.white.withAlpha(13),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: Colors.white70, size: 24)
                  : Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: isSpecial ? FontWeight.normal : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton(
        onPressed: _submitTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: theme.primaryColor.withAlpha(128),
        ),
        child: const Text(
          "SAVE TRANSACTION",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS ---

  String _formatDateSmart(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
