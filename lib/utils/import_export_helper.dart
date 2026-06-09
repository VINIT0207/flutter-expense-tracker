import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';

/// Utility class for importing and exporting transactions to/from CSV format.
class ImportExportHelper {
  /// Export columns matching the import format
  static const List<String> csvHeaders = [
    'id',
    'title',
    'category',
    'amount',
    'date',
    'isEssential',
    'note',
  ];

  /// Export transactions to CSV format
  /// Returns the CSV string content
  static String exportToCSV(List<TransactionModel> transactions) {
    final List<List<dynamic>> rows = [];

    // Add header row
    rows.add(csvHeaders);

    // Add data rows
    for (var tx in transactions) {
      rows.add([
        tx.id ?? '',
        tx.title,
        tx.category,
        tx.amount,
        tx.date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        tx.isEssential ? 'true' : 'false',
        tx.note ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Import transactions from CSV file
  /// Returns a list of parsed transactions
  /// Throws FormatException if the CSV format is invalid
  static Future<List<TransactionModel>> importFromCSV(String filePath) async {
    final file = File(filePath);
    final csvString = await file.readAsString();

    return parseCSVContent(csvString);
  }

  /// Parse CSV content and return transactions
  /// This works for both file content and string content
  static List<TransactionModel> parseCSVContent(String csvString) {
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      fieldDelimiter: ',',
      shouldParseNumbers: true,
    ).convert(csvString);

    if (rows.isEmpty) {
      throw const FormatException("Empty CSV file");
    }

    // Find header row index (first row containing expected headers)
    int headerIndex = -1;
    for (int i = 0; i < rows.length && i < 5; i++) {
      final firstCell = rows[i][0].toString().toLowerCase();
      if (firstCell == 'id' || firstCell == 'title') {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1) {
      throw const FormatException("Could not find header row. Expected 'id' or 'title' in first column.");
    }

    final headers = rows[headerIndex].map((e) => e.toString().toLowerCase().trim()).toList();

    // Validate required columns
    final requiredColumns = ['title', 'category', 'amount', 'date'];
    for (var col in requiredColumns) {
      if (!headers.contains(col)) {
        throw FormatException("Missing required column: $col");
      }
    }

    final transactions = <TransactionModel>[];
    final errors = <String>[];

    // Process data rows
    for (int i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row[0] == null || row[0].toString().isEmpty) {
        continue; // Skip empty rows
      }

      try {
        final tx = parseRow(row, headers);
        if (tx != null) {
          transactions.add(tx);
        }
      } catch (e) {
        errors.add("Row ${i + 1}: ${e.toString()}");
      }
    }

    if (transactions.isEmpty && errors.isNotEmpty) {
      throw FormatException("No valid transactions found. Errors:\n${errors.join('\n')}");
    }

    return transactions;
  }

  /// Parse a single CSV row into a TransactionModel
  static TransactionModel? parseRow(List<dynamic> row, List<String> headers) {
    final Map<String, dynamic> values = {};
    
    for (int j = 0; j < headers.length && j < row.length; j++) {
      values[headers[j]] = row[j];
    }

    // Extract required fields
    final title = values['title']?.toString().trim();
    final category = values['category']?.toString().trim();
    final amountStr = values['amount']?.toString();
    final dateStr = values['date']?.toString().trim();

    // Validate required fields
    if (title == null || title.isEmpty) {
      throw Exception("Missing title");
    }
    if (category == null || category.isEmpty) {
      throw Exception("Missing category for '$title'");
    }
    if (amountStr == null || amountStr.isEmpty) {
      throw Exception("Missing amount for '$title'");
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      throw Exception("Invalid amount '$amountStr' for '$title'");
    }

    if (dateStr == null || dateStr.isEmpty) {
      throw Exception("Missing date for '$title'");
    }

    // Parse date (supports YYYY-MM-DD or YYYY/MM/DD)
    final dateParts = dateStr.split(RegExp(r'[-/]'));
    if (dateParts.length != 3) {
      throw Exception("Invalid date format '$dateStr' for '$title'. Use YYYY-MM-DD");
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      throw Exception("Invalid date '$dateStr' for '$title'");
    }

    // Parse optional fields
    final isEssentialStr = values['isEssential']?.toString().toLowerCase();
    final isEssential = isEssentialStr == 'true' || isEssentialStr == '1' || isEssentialStr == 'yes';
    final note = values['note']?.toString().trim();

    return TransactionModel(
      title: title,
      category: category,
      amount: amount,
      date: date,
      isEssential: isEssential,
      note: note,
    );
  }

  /// Pick a CSV file for import
  static Future<PlatformFile?> pickCSVFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    return result?.files.first;
  }

  /// Get the export CSV data for saving to file
  static List<int> getExportBytes(List<TransactionModel> transactions) {
    final csvContent = exportToCSV(transactions);
    return csvContent.codeUnits;
  }
}

