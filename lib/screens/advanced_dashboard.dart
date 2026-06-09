import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/finance_provider.dart';
import '../models/transaction.dart';

const Color kPrimaryColor = Color(0xFF6366F1);
const Color kSecondaryColor = Color(0xFF10B981);
const Color kDangerColor = Color(0xFFEF4444);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kSurfaceColor = Color(0xFF1E293B);
const Color kBackgroundColor = Color(0xFF0F172A);

enum TimeRange { week, month, year, all }
enum ChartType { trend, category, spread }

class AdvancedDashboard extends StatefulWidget {
  const AdvancedDashboard({super.key});

  @override
  State<AdvancedDashboard> createState() => _AdvancedDashboardState();
}

class _AdvancedDashboardState extends State<AdvancedDashboard>
    with TickerProviderStateMixin {
  TimeRange _selectedRange = TimeRange.month;
  ChartType _selectedChart = ChartType.trend;
  int _touchedIndex = -1;
  final bool _isExporting = false;
  bool _isImporting = false;

  late AnimationController _fadeController;
  late AnimationController _chartTransitionController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController.forward();
    _chartTransitionController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartTransitionController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return allTxs.where((tx) => tx.date.isAfter(startOfWeek)).toList();
      case TimeRange.month:
        return allTxs
            .where((tx) =>
                tx.date.month == now.month && tx.date.year == now.year)
            .toList();
      case TimeRange.year:
        return allTxs.where((tx) => tx.date.year == now.year).toList();
      case TimeRange.all:
      default:
        return allTxs;
    }
  }

  List<TransactionModel> _getPreviousPeriodTransactions(
      List<TransactionModel> allTxs) {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.week:
        final startOfCurrentWeek =
            now.subtract(Duration(days: now.weekday - 1));
        final startOfPreviousWeek =
            startOfCurrentWeek.subtract(const Duration(days: 7));
        final endOfPreviousWeek =
            startOfCurrentWeek.subtract(const Duration(days: 1));
        return allTxs
            .where((tx) =>
                tx.date.isAfter(startOfPreviousWeek) &&
                tx.date.isBefore(endOfPreviousWeek))
            .toList();
      case TimeRange.month:
        final previousMonth = DateTime(now.year, now.month - 1);
        return allTxs
            .where((tx) =>
                tx.date.month == previousMonth.month &&
                tx.date.year == previousMonth.year)
            .toList();
      case TimeRange.year:
        return allTxs.where((tx) => tx.date.year == now.year - 1).toList();
      case TimeRange.all:
      default:
        if (allTxs.length < 2) return [];
        final midPoint = allTxs.length ~/ 2;
        return allTxs.sublist(0, midPoint);
    }
  }

  Map<String, dynamic> _calculateTrend(List<TransactionModel> currentTxs,
      List<TransactionModel> previousTxs) {
    final currentTotal =
        currentTxs.fold(0.0, (sum, item) => sum + item.amount);
    final previousTotal =
        previousTxs.fold(0.0, (sum, item) => sum + item.amount);

    if (previousTotal == 0) {
      return {'percent': 0, 'isPositive': false, 'message': 'No previous data'};
    }

    final percentChange = ((currentTotal - previousTotal) / previousTotal) * 100;
    final isPositive = percentChange < 0;

    String message;
    if (percentChange.abs() < 5) {
      message = isPositive ? 'Slightly under control' : 'Slightly higher';
    } else if (percentChange.abs() < 15) {
      message = isPositive ? 'Under control' : 'Notable increase';
    } else {
      message = isPositive ? 'Well controlled!' : 'Significant increase';
    }

    return {
      'percent': percentChange.abs(),
      'isPositive': isPositive,
      'message': message,
    };
  }

  String _getPeriodLabel() {
    switch (_selectedRange) {
      case TimeRange.week:
        return "last week";
      case TimeRange.month:
        return "last month";
      case TimeRange.year:
        return "last year";
      case TimeRange.all:
        return "earlier";
    }
  }

  String _getVolumeLabel(int count) {
    if (count == 0) return "None";
    if (count < 5) return "Low";
    if (count < 15) return "Medium";
    if (count < 30) return "High";
    return "Very High";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final filteredTxs = _filterTransactions(provider.transactions);

    filteredTxs.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildTimeRangeSelector(),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: _buildSummaryCards(filteredTxs, provider.transactions),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChartSection(context, filteredTxs),
          ),
          SliverToBoxAdapter(
            child: _buildAIInsights(filteredTxs),
          ),
          _buildCategoryBreakdownSliver(filteredTxs),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleExport(context),
        backgroundColor: kPrimaryColor,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.download_rounded),
        label: Text(_isExporting ? "EXPORTING..." : "EXPORT CSV"),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: kBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          "Analytics",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kPrimaryColor.withAlpha(26),
                kBackgroundColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _isImporting
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () => _handleImport(context),
                tooltip: "Import CSV",
              ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 45,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        children: TimeRange.values.map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRange = range);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  range.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(
      List<TransactionModel> txs, List<TransactionModel> allTxs) {
    double total = txs.fold(0, (sum, item) => sum + item.amount);
    double avg = txs.isEmpty ? 0 : total / txs.length;

    double burnRate = 0;
    if (txs.isNotEmpty) {
      final days = txs.last.date.difference(txs.first.date).inDays + 1;
      burnRate = total / (days > 0 ? days : 1);
    }

    final previousTxs = _getPreviousPeriodTransactions(allTxs);
    final trendData = _calculateTrend(txs, previousTxs);
    final String trendPercent = "${trendData['percent'].toStringAsFixed(0)}%";
    final bool trendIsPositive = trendData['isPositive'] as bool;
    final String periodLabel = _getPeriodLabel();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCardWithTrend(
                  title: "TOTAL SPENT",
                  value: "₹${total.toStringAsFixed(0)}",
                  icon: Icons.attach_money,
                  color: kPrimaryColor,
                  trendPercent: trendPercent,
                  trendMessage: "vs $periodLabel",
                  isPositive: trendIsPositive,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCardWithTrend(
                  title: "DAILY BURN",
                  value: "₹${burnRate.toStringAsFixed(0)}",
                  icon: Icons.local_fire_department,
                  color: kDangerColor,
                  trendPercent: burnRate > 0 ? "Active" : "N/A",
                  trendMessage: burnRate > 0 ? "per day avg" : "No data",
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCardWithTrend(
                  title: "AVG TRANSACTION",
                  value: "₹${avg.toStringAsFixed(0)}",
                  icon: Icons.functions,
                  color: kSecondaryColor,
                  trendPercent: txs.isNotEmpty ? "${txs.length}" : "0",
                  trendMessage: "transactions",
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCardWithTrend(
                  title: "TRANSACTIONS",
                  value: "${txs.length}",
                  icon: Icons.receipt_long,
                  color: kWarningColor,
                  trendPercent: _getVolumeLabel(txs.length),
                  trendMessage: "count",
                  isPositive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
      BuildContext context, List<TransactionModel> txs) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Visual Analysis",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  _ChartTypeBtn(
                      icon: Icons.show_chart,
                      type: ChartType.trend,
                      selected: _selectedChart,
                      onTap: (t) => setState(() => _selectedChart = t)),
                  const SizedBox(width: 8),
                  _ChartTypeBtn(
                      icon: Icons.pie_chart_outline,
                      type: ChartType.category,
                      selected: _selectedChart,
                      onTap: (t) => setState(() => _selectedChart = t)),
                  const SizedBox(width: 8),
                  _ChartTypeBtn(
                      icon: Icons.bar_chart,
                      type: ChartType.spread,
                      selected: _selectedChart,
                      onTap: (t) => setState(() => _selectedChart = t)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _renderSelectedChart(txs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderSelectedChart(List<TransactionModel> txs) {
    if (txs.isEmpty) {
      return const Center(
          child: Text("Not enough data to graph",
              style: TextStyle(color: Colors.white38)));
    }

    switch (_selectedChart) {
      case ChartType.trend:
        return _buildTrendLineChart(txs);
      case ChartType.category:
        return _buildCategoryPieChart(txs);
      case ChartType.spread:
        return _buildSpreadBarChart(txs);
    }
  }

  Widget _buildTrendLineChart(List<TransactionModel> txs) {
    Map<int, double> dailyTotals = {};
    for (var tx in txs) {
      int day = tx.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + tx.amount;
    }

    List<FlSpot> spots = dailyTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10));
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient:
                const LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  kPrimaryColor.withAlpha(77),
                  kPrimaryColor.withAlpha(0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: kSurfaceColor,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  'Day ${touchedSpot.x.toInt()} \n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '₹${touchedSpot.y.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: kSecondaryColor, fontWeight: FontWeight.w900),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<TransactionModel> txs) {
    Map<String, double> categories = {};
    for (var tx in txs) {
      categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
    }

    final total = categories.values.fold(0.0, (sum, val) => sum + val);

    List<PieChartSectionData> sections = [];
    int index = 0;
    List<Color> colors = [
      kPrimaryColor,
      kSecondaryColor,
      kWarningColor,
      kDangerColor,
      Colors.purple,
      Colors.cyan
    ];

    categories.forEach((key, value) {
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final percent = (value / total * 100);

      if (percent > 3) {
        sections.add(PieChartSectionData(
          color: colors[index % colors.length],
          value: value,
          title: '${percent.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
          badgeWidget: isTouched
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(key,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white)),
                )
              : null,
          badgePositionPercentageOffset: 1.3,
        ));
      }
      index++;
    });

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
              HapticFeedback.selectionClick();
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  Widget _buildSpreadBarChart(List<TransactionModel> txs) {
    double essential = 0;
    double optional = 0;

    for (var tx in txs) {
      if (tx.isEssential) {
        essential += tx.amount;
      } else {
        optional += tx.amount;
      }
    }

    double maxY = math.max(essential, optional) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: kSurfaceColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = group.x == 0 ? "Essential" : "Optional";
              return BarTooltipItem(
                "$label\n",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                      text: "₹${rod.toY.toStringAsFixed(0)}",
                      style: const TextStyle(color: kSecondaryColor))
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    value == 0 ? "NEEDS" : "WANTS",
                    style: const TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                  toY: essential,
                  color: kPrimaryColor,
                  width: 30,
                  borderRadius: BorderRadius.circular(6)),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                  toY: optional,
                  color: kWarningColor,
                  width: 30,
                  borderRadius: BorderRadius.circular(6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(List<TransactionModel> txs) {
    if (txs.isEmpty) return const SizedBox.shrink();

    String insight = "Spending seems stable.";
    IconData icon = Icons.check_circle_outline;
    Color color = kSecondaryColor;

    double total = txs.fold(0, (sum, i) => sum + i.amount);
    double optional =
        txs.where((t) => !t.isEssential).fold(0, (sum, i) => sum + i.amount);

    if (total > 0 && (optional / total) > 0.4) {
      insight =
          "You spent ${((optional / total) * 100).toStringAsFixed(0)}% on 'Wants' this period. Consider cutting back on Entertainment.";
      icon = Icons.warning_amber_rounded;
      color = kWarningColor;
    } else if (total > 0 && (optional / total) < 0.1) {
      insight =
          "Great discipline! Only ${((optional / total) * 100).toStringAsFixed(0)}% discretionary spending.";
      icon = Icons.thumb_up_alt_outlined;
      color = kSecondaryColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withAlpha(51), kSurfaceColor]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI INSIGHT",
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(insight,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownSliver(List<TransactionModel> txs) {
    Map<String, double> catTotals = {};
    for (var tx in txs) {
      catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
    }

    var sortedEntries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("Spending by Category",
                  style: TextStyle(
                      color: Colors.white54, fontWeight: FontWeight.bold)),
            );
          }

          final entry = sortedEntries[index - 1];
          final total = txs.fold(0.0, (sum, t) => sum + t.amount);
          final percent = (entry.value / total);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.key[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text("₹${entry.value.toStringAsFixed(0)}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white10,
                          color: _getColorForCategory(entry.key),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: sortedEntries.length + 1,
      ),
    );
  }

  Color _getColorForCategory(String cat) {
    final colors = [
      kPrimaryColor,
      kSecondaryColor,
      kWarningColor,
      Colors.purple,
      Colors.pink,
      Colors.teal
    ];
    return colors[cat.hashCode.abs() % colors.length];
  }

  // --- EXPORT FUNCTIONALITY ---
  Future<void> _handleExport(BuildContext context) async {
    // TODO: Implement real CSV export functionality
    // For now, just show a snackbar
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Export feature coming soon!"),
            ],
          ),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    /*
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    setState(() => _isExporting = true);

    try {
      final csvContent = provider.exportTransactionsToCSV();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.csv';

      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(csvContent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Transactions exported successfully"),
                ],
              ),
              backgroundColor: kSecondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text("Export failed: ${e.toString()}"),
              ],
            ),
            backgroundColor: kDangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
    */
  }

  // --- IMPORT FUNCTIONALITY ---
  Future<void> _handleImport(BuildContext context) async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Force bytes mode
      );

      if (result != null) {
        final provider = Provider.of<FinanceProvider>(context, listen: false);
        String csvContent;
        
        // Try to get content from bytes first (preferred for web/mobile)
        if (result.files.single.bytes != null) {
          csvContent = utf8.decode(result.files.single.bytes!);
        } 
        // Fallback to path for desktop
        else if (result.files.single.path != null) {
          csvContent = await File(result.files.single.path!).readAsString();
        } else {
          throw Exception("Could not read file content");
        }
        
        final count = await provider.importTransactionsFromBytes(csvContent);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Successfully imported $count transactions"),
                ],
              ),
              backgroundColor: kSecondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text("Import failed: ${e.toString()}"),
              ],
            ),
            backgroundColor: kDangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }
}

class _ChartTypeBtn extends StatelessWidget {
  final IconData icon;
  final ChartType type;
  final ChartType selected;
  final Function(ChartType) onTap;

  const _ChartTypeBtn(
      {required this.icon,
      required this.type,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: isSelected ? kPrimaryColor : Colors.white10),
        ),
        child:
            Icon(icon, color: isSelected ? kPrimaryColor : Colors.white54, size: 20),
      ),
    );
  }
}

class _StatCardWithTrend extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trendPercent;
  final String trendMessage;
  final bool isPositive;

  const _StatCardWithTrend(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color,
      required this.trendPercent,
      required this.trendMessage,
      required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? kSecondaryColor : kDangerColor)
                      .withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 10,
                      color: isPositive ? kSecondaryColor : kDangerColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trendPercent,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? kSecondaryColor : kDangerColor,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(trendMessage,
              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(77))),
        ],
      ),
    );
  }
}
