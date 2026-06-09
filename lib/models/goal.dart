
/// Model class representing a savings goal.
class GoalModel {
  final int? id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final bool isCompleted;

  const GoalModel({
    this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.targetDate,
    this.isCompleted = false,
  });

  /// Amount still needed to reach the goal
  double get remainingAmount => targetAmount - savedAmount;

  /// Progress percentage (0.0 to 1.0)
  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  /// Days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return difference > 0 ? difference : 1; // Avoid division by zero
  }

  /// Daily savings needed to hit the goal on time
  double get dailySavingsNeeded {
    if (isCompleted || savedAmount >= targetAmount) return 0;
    return remainingAmount / daysRemaining;
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  /// Create from database map
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0).toDouble(),
      targetDate: DateTime.tryParse(map['targetDate'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      isCompleted: (map['isCompleted'] ?? 0) == 1,
    );
  }

  /// Create a copy with modified fields
  GoalModel copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'GoalModel(id: $id, title: $title, targetAmount: $targetAmount, savedAmount: $savedAmount, progress: ${(progress * 100).toStringAsFixed(0)}%)';
  }
}

