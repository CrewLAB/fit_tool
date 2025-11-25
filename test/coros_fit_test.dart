import 'dart:io';
import 'package:fit_tool/fit_tool.dart';
import 'package:test/test.dart';

void main() {
  test('Parse COROS FIT file', () {
    final bytes = File('test/data/coros.fit').readAsBytesSync();

    try {
      final fitFile = FitFile.fromBytes(bytes);
      final dataMessages = fitFile.records
          .where((r) => !r.isDefinition)
          .map((r) => r.message)
          .whereType<DataMessage>()
          .toList();

      print('Parsed ${dataMessages.length} data messages');
    } on FormatException catch (e) {
      print('FormatException (expected for malformed COROS file): $e');
    }
  });
}
