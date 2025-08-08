import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/expense.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isSyncing = false;

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final CurrencyService _currencyService = CurrencyService();
  final NotificationService _notificationService = NotificationService();
  final ReportService _reportService = ReportService();

  // Getters
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

  List<Expense> get allExpenses => _expenses;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  // Service getters
  CurrencyService get currencyService => _currencyService;
  NotificationService get notificationService => _notificationService;
  ReportService get reportService => _reportService;

  // Constructor
  ExpenseViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _currencyService.initialize();
    await _notificationService.initialize();
    await loadExpenses();

    // Set up real-time sync if user is authenticated
    _setupRealtimeSync();
  }

  void _setupRealtimeSync() {
    final authService = AuthService();
    if (authService.isAuthenticated) {
      final stream = _firestoreService.expenseStream();
      stream?.listen((cloudExpenses) {
        // Merge cloud expenses with local ones
        _mergeCloudExpenses(cloudExpenses);
      });
    }
  }

  void _mergeCloudExpenses(List<Expense> cloudExpenses) {
    // Simple merge strategy - replace local with cloud data
    // In a production app, you might want more sophisticated conflict resolution
    final localIds = _expenses.map((e) => e.id).toSet();
    final cloudIds = cloudExpenses.map((e) => e.id).toSet();

    // Add new expenses from cloud
    for (final cloudExpense in cloudExpenses) {
      if (!localIds.contains(cloudExpense.id)) {
        _expenses.add(cloudExpense);
      }
    }

    // Remove deleted expenses (exists locally but not in cloud)
    _expenses.removeWhere((expense) => !cloudIds.contains(expense.id));

    // Update existing expenses with cloud data
    for (int i = 0; i < _expenses.length; i++) {
      final cloudExpense = cloudExpenses.firstWhere(
        (e) => e.id == _expenses[i].id,
        orElse: () => _expenses[i],
      );
      _expenses[i] = cloudExpense;
    }

    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage first
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('expenses');
      if (data != null) {
        final List<dynamic> jsonData = jsonDecode(data);
        _expenses = jsonData.map((e) => Expense.fromJson(e)).toList();
      }

      // Try to load from cloud if user is authenticated
      final authService = AuthService();
      if (authService.isAuthenticated) {
        final cloudExpenses = await _firestoreService.loadExpensesFromCloud();
        if (cloudExpenses.isNotEmpty) {
          _mergeCloudExpenses(cloudExpenses);
          await _saveExpensesToLocal(); // Save merged data locally
        }
      }
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _saveExpensesToLocal();

    // Sync to cloud if authenticated
    final authService = AuthService();
    if (authService.isAuthenticated) {
      await _firestoreService.addExpenseToCloud(expense);
    }

    notifyListeners();

    // Show success notification
    await _notificationService.showInstantNotification(
      title: 'Expense Added',
      body:
          'Added ${expense.title} for ${_currencyService.formatAmount(expense.amount)}',
    );
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpensesToLocal();

    // Sync to cloud if authenticated
    final authService = AuthService();
    if (authService.isAuthenticated) {
      await _firestoreService.deleteExpenseFromCloud(id);
    }

    notifyListeners();
  }

  Future<void> syncToCloud() async {
    final authService = AuthService();
    if (!authService.isAuthenticated) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _firestoreService.syncExpensesToCloud(_expenses);

      await _notificationService.showInstantNotification(
        title: 'Sync Complete',
        body: 'Your expenses have been synced to the cloud',
      );
    } catch (e) {
      print('Error syncing to cloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
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

  Future<void> _saveExpensesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData =
        jsonEncode(_expenses.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', jsonData);
  }

  // Currency conversion methods
  double convertExpenseAmount(Expense expense, String targetCurrency) {
    // Assuming expenses are stored in the user's selected currency
    return _currencyService.convertAmount(
      expense.amount,
      _currencyService.selectedCurrency,
      targetCurrency,
    );
  }

  String formatExpenseAmount(Expense expense, [String? currency]) {
    final amount = currency != null
        ? convertExpenseAmount(expense, currency)
        : expense.amount;
    return _currencyService.formatAmount(amount, currency);
  }

  // Report generation methods
  Future<DailyReport> generateDailyReport(DateTime date) async {
    return await _reportService.generateDailyReport(_expenses, date);
  }

  Future<WeeklyReport> generateWeeklyReport(DateTime startDate) async {
    return await _reportService.generateWeeklyReport(_expenses, startDate);
  }

  Future<MonthlyReport> generateMonthlyReport(DateTime month) async {
    return await _reportService.generateMonthlyReport(_expenses, month);
  }

  Future<void> shareReport(dynamic report) async {
    await _reportService.shareReport(report);
  }

  // Notification settings
  Future<void> setDailyReminder({
    required bool enabled,
    int hour = 20,
    int minute = 0,
  }) async {
    if (enabled) {
      await _notificationService.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        title: 'Daily Expense Reminder',
        body: "Don't forget to track your expenses today!",
      );
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  Future<void> setWeeklyReport({
    required bool enabled,
    int weekday = 7, // Sunday
    int hour = 10,
    int minute = 0,
  }) async {
    if (enabled) {
      await _notificationService.scheduleWeeklyReport(
        weekday: weekday,
        hour: hour,
        minute: minute,
        title: 'Weekly Expense Report',
        body: 'Your weekly spending summary is ready!',
      );
    } else {
      await _notificationService.cancelWeeklyReport();
    }
  }

  // Analytics methods
  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
  double get totalSpentAll => _expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryBreakdown {
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  Map<String, int> get categoryCount {
    final count = <String, int>{};
    for (final expense in expenses) {
      count[expense.category] = (count[expense.category] ?? 0) + 1;
    }
    return count;
  }

  double getAverageDailySpending([int? days]) {
    if (expenses.isEmpty) return 0;

    final totalDays = days ??
        (_startDate != null && _endDate != null
            ? _endDate!.difference(_startDate!).inDays + 1
            : 30); // Default to 30 days

    return totalSpent / totalDays;
  }

  String getTopCategory() {
    final breakdown = categoryBreakdown;
    if (breakdown.isEmpty) return '';

    return breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<Expense> getRecentExpenses({int limit = 5}) {
    final sortedExpenses = List<Expense>.from(_expenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(limit).toList();
  }

  // Search and filter methods
  List<Expense> searchExpenses(String query) {
    if (query.isEmpty) return expenses;

    final lowerQuery = query.toLowerCase();
    return expenses
        .where((expense) =>
            expense.title.toLowerCase().contains(lowerQuery) ||
            expense.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  List<Expense> getExpensesByCategory(String category) {
    return expenses.where((expense) => expense.category == category).toList();
  }

  List<Expense> getExpensesInRange(DateTime start, DateTime end) {
    return _expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Budget tracking methods
  double getBudgetUsage(double budgetAmount, String period) {
    double totalSpending = 0;
    final now = DateTime.now();
    DateTime startDate;

    switch (period.toLowerCase()) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    final periodExpenses = getExpensesInRange(startDate, now);
    totalSpending =
        periodExpenses.fold(0, (sum, expense) => sum + expense.amount);

    return (totalSpending / budgetAmount * 100).clamp(0, 100);
  }

  bool isOverBudget(double budgetAmount, String period) {
    return getBudgetUsage(budgetAmount, period) > 100;
  }
}
