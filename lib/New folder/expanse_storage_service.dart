import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../model/expense.dart';

class ExpenseStorageService {
  static const _fileName = 'expenses.json';

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<File> _getFile() async {
    final path = await _getFilePath();
    return File(path);
  }

  Future<List<Expense>> loadExpenses() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      final List decoded = jsonDecode(contents);
      return decoded.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    try {
      final file = await _getFile();
      final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {}
  }

  Future<void> clearAllExpenses() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
