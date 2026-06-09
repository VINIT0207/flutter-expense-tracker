/// A robust, immutable data model representing a single financial record.
///
/// Includes serialization logic for SQLite and helper methods for state management.
class TransactionModel {
  /// Unique ID assigned by the database. Null for new, unsaved records.
  final int? id;

  /// A short description of the expense (e.g., "Lunch at Subway").
  /// Often defaults to the Category name if not specified by the user.
  final String title;

  /// The broader group this record belongs to (e.g., "Food", "Transport").
  /// Used for aggregation in the Pie Chart.
  final String category;

  /// The monetary value of the transaction.
  final double amount;

  /// The exact timestamp of when this occurred.
  final DateTime date;

  /// Critical for the AI Decision Engine.
  /// true = Needs (Rent, Food) | false = Wants (Games, Cafe)
  final bool isEssential;

  /// Optional context (e.g., "Monthly subscription").
  final String? note;

  const TransactionModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isEssential,
    this.note,
  });

  /// Creates a copy of this object with the given fields replaced.
  /// Useful for editing transactions without mutating the original instance.
  TransactionModel copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    bool? isEssential,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isEssential: isEssential ?? this.isEssential,
      note: note ?? this.note,
    );
  }

  /// Converts the object to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      // Store date as ISO8601 string to preserve sorting capability
      'date': date.toIso8601String(),
      'isEssential': isEssential ? 1 : 0, // SQLite stores bools as 0/1
      'note': note,
    };
  }

  /// Creates an object from a Map (retrieved from SQLite).
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(), // Safely handles int/double from DB
      date: DateTime.parse(map['date'] as String),
      isEssential: (map['isEssential'] as int) == 1,
      note: map['note'] as String?,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, date: $date, essential: $isEssential)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionModel &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.amount == amount &&
        other.date == date &&
        other.isEssential == isEssential &&
        other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    title.hashCode ^
    category.hashCode ^
    amount.hashCode ^
    date.hashCode ^
    isEssential.hashCode ^
    note.hashCode;
  }
}