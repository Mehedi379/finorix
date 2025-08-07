import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/expense.dart';

class ExpenseViewModel extends ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Filtered expenses based on date range
  List<Expense> get expenses {
    if (_startDate == null || _endDate == null) {
      return _expenses;
    }

    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final startDate = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final endDate = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
      );

      return expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // All expenses (unfiltered) - for settings screen export
  List<Expense> get allExpenses => _expenses;

  // Date filter getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Constructor
  ExpenseViewModel() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('expenses');
    if (data != null) {
      final List<dynamic> jsonData = jsonDecode(data);
      _expenses = jsonData.map((e) => Expense.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _saveExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpenses();
    notifyListeners();
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData =
        jsonEncode(_expenses.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', jsonData);
  }

  // Total spent for filtered expenses
  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);

  // Total spent for all expenses
  double get totalSpentAll => _expenses.fold(0, (sum, e) => sum + e.amount);
}
