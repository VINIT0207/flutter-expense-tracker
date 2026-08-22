import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/utils/import_export_helper.dart';
import 'package:finance_tracker/models/transaction.dart';

void main() {
  group('ImportExportHelper Tests', () {
    test('exportToCSV and parseCSVContent round trip', () {
      final sampleTxs = [
        TransactionModel(
          id: 1,
          title: 'Grocery Mart',
          category: 'Food',
          amount: 1450.50,
          date: DateTime(2026, 8, 15),
          isEssential: true,
          note: 'Weekly essentials',
        ),
        TransactionModel(
          id: 2,
          title: 'Movie Night',
          category: 'Entertainment',
          amount: 600.0,
          date: DateTime(2026, 8, 16),
          isEssential: false,
          note: 'IMAX 3D',
        ),
      ];

      final csvString = ImportExportHelper.exportToCSV(sampleTxs);
      expect(csvString.contains('Grocery Mart'), isTrue);
      expect(csvString.contains('Movie Night'), isTrue);

      final parsed = ImportExportHelper.parseCSVContent(csvString);
      expect(parsed.length, 2);
      expect(parsed[0].title, 'Grocery Mart');
      expect(parsed[0].amount, 1450.50);
      expect(parsed[0].isEssential, isTrue);
      expect(parsed[1].title, 'Movie Night');
      expect(parsed[1].isEssential, isFalse);
    });

    test('parseCSVContent throws FormatException on empty or invalid headers', () {
      expect(() => ImportExportHelper.parseCSVContent(''), throwsA(isA<FormatException>()));
      expect(
        () => ImportExportHelper.parseCSVContent('foo,bar\n1,2'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
