import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// --- LOGIC IMPORTS ---
import '../logic/finance_provider.dart';
import '../models/transaction.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFF6366F1);
const Color kSurfaceColor = Color(0xFF1E293B);
const Color kBackgroundColor = Color(0xFF0F172A);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // --- STATE VARIABLES ---
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Filters
  bool _showEssentialOnly = false;
  bool _showHighValueOnly = false; // > 500
  DateTimeRange? _dateRange;
  String _searchQuery = "";

  // Selection Mode
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- DATA LOGIC ---

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTxs) {
    return allTxs.where((tx) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesCategory = tx.category.toLowerCase().contains(query);
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesNote = tx.note?.toLowerCase().contains(query) ?? false;
        final matchesAmount = tx.amount.toString().contains(query);

        if (!matchesCategory && !matchesTitle && !matchesNote && !matchesAmount) {
          return false;
        }
      }

      // 2. Essential Filter
      if (_showEssentialOnly && !tx.isEssential) return false;

      // 3. High Value Filter
      if (_showHighValueOnly && tx.amount < 500) return false;

      // 4. Date Range
      if (_dateRange != null) {
        if (tx.date.isBefore(_dateRange!.start) || tx.date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList()
    // Sort descending by date
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<TransactionModel>> _groupTransactionsByMonth(List<TransactionModel> txs) {
    Map<String, List<TransactionModel>> grouped = {};

    for (var tx in txs) {
      final key = DateFormat('MMMM yyyy').format(tx.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final filteredList = _getFilteredTransactions(provider.transactions);
    final groupedList = _groupTransactionsByMonth(filteredList);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, filteredList.length),
          _buildFilterBar(),
        ],
        body: filteredList.isEmpty
            ? _buildEmptyState()
            : _buildGroupedList(groupedList),
      ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBar(context, provider) : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int count) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: kBackgroundColor,
      elevation: 0,
      title: _isSelectionMode
          ? Text("${_selectedIds.length} Selected", style: const TextStyle(color: Colors.white))
          : const Text("Transaction History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      leading: _isSelectionMode
          ? IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        }),
      )
          : IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDateRange,
            tooltip: "Filter by Date",
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search transactions...",
              hintStyle: TextStyle(color: Colors.white.withAlpha(102)),
              prefixIcon: Icon(Icons.search, color: kPrimaryColor.withAlpha(204)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
              )
                  : null,
              filled: true,
              fillColor: kSurfaceColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _FilterChip(
              label: "Essential Only",
              isSelected: _showEssentialOnly,
              onTap: () => setState(() => _showEssentialOnly = !_showEssentialOnly),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "High Value (>500)",
              isSelected: _showHighValueOnly,
              onTap: () => setState(() => _showHighValueOnly = !_showHighValueOnly),
            ),
            const SizedBox(width: 8),
            if (_dateRange != null)
              InputChip(
                label: Text(
                  "${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: kPrimaryColor.withAlpha(51),
                onDeleted: () => setState(() => _dateRange = null),
                deleteIconColor: Colors.white70,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(Map<String, List<TransactionModel>> groupedList) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groupedList.length,
      itemBuilder: (context, index) {
        String monthKey = groupedList.keys.elementAt(index);
        List<TransactionModel> txs = groupedList[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky-like Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthKey.toUpperCase(),
                    style: TextStyle(
                      color: kPrimaryColor.withAlpha(204),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Total: ₹${txs.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 12),
                  ),
                ],
              ),
            ),
            // List of items in this month
            ...txs.map((tx) => _buildTransactionItem(tx)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final isSelected = _selectedIds.contains(tx.id);

    return InkWell(
      onLongPress: () {
        HapticFeedback.selectionClick();
        setState(() {
          _isSelectionMode = true;
          _selectedIds.add(tx.id!);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(tx.id!);
              if (_selectedIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIds.add(tx.id!);
            }
          });
        } else {
          // Show details or edit (future feature)
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withAlpha(51) : kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: kPrimaryColor)
              : Border.all(color: Colors.transparent),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tx.isEssential ? Colors.blue.withAlpha(26) : Colors.orange.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForCategory(tx.category),
                  size: 20,
                  color: tx.isEssential ? Colors.blue : Colors.orange,
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Text(
            tx.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d • h:mm a').format(tx.date),
                style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 12),
              ),
              if (tx.note != null && tx.note!.isNotEmpty)
                Text(
                  tx.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          trailing: Text(
            "- ₹${tx.amount.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, FinanceProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: kSurfaceColor,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIds.clear();
                  for (var tx in provider.transactions) {
                    _selectedIds.add(tx.id!);
                  }
                });
              },
              child: const Text("Select All"),
            ),
            ElevatedButton.icon(
              onPressed: () => _confirmDelete(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white.withAlpha(51)),
          const SizedBox(height: 16),
          Text(
            "No records found",
            style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 16),
          ),
          if (_searchQuery.isNotEmpty || _dateRange != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = "";
                  _dateRange = null;
                  _showEssentialOnly = false;
                  _showHighValueOnly = false;
                });
              },
              child: const Text("Clear Filters"),
            ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kPrimaryColor,
              surface: kSurfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text("Delete Transactions?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} records? This cannot be undone.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (var id in _selectedIds) {
                await provider.deleteTransaction(id);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transactions deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper to map category strings to icons (matches your other files)
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_bus;
      case 'shopping': return Icons.shopping_bag;
      case 'fun': return Icons.gamepad;
      case 'bills': return Icons.receipt_long;
      case 'health': return Icons.medical_services;
      case 'education': return Icons.school;
      case 'travel': return Icons.flight;
      default: return Icons.category;
    }
  }
}

// --- SUB-WIDGETS ---

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.white.withAlpha(26),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
