import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/expense.dart';
import 'currency_service.dart';
import 'notification_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final CurrencyService _currencyService = CurrencyService();
  final NotificationService _notificationService = NotificationService();

  Future<DailyReport> generateDailyReport(
      List<Expense> expenses, DateTime date) async {
    final dayExpenses = expenses.where((expense) {
      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return expenseDate.isAtSameMomentAs(targetDate);
    }).toList();

    final totalAmount =
        dayExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categoryBreakdown = <String, double>{};
    final categoryCount = <String, int>{};

    for (final expense in dayExpenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] =
          (categoryCount[expense.category] ?? 0) + 1;
    }

    final topCategory = categoryBreakdown.isNotEmpty
        ? categoryBreakdown.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;

    return DailyReport(
      date: date,
      expenses: dayExpenses,
      totalAmount: totalAmount,
      categoryBreakdown: categoryBreakdown,
      categoryCount: categoryCount,
      topCategory: topCategory,
      expenseCount: dayExpenses.length,
    );
  }

  Future<WeeklyReport> generateWeeklyReport(
      List<Expense> expenses, DateTime startDate) async {
    final endDate = startDate.add(const Duration(days: 6));

    final weekExpenses = expenses.where((expense) {
      return expense.date
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalAmount =
        weekExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categoryBreakdown = <String, double>{};
    final dailyTotals = <DateTime, double>{};
    final categoryCount = <String, int>{};

    for (final expense in weekExpenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] =
          (categoryCount[expense.category] ?? 0) + 1;

      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[expenseDate] =
          (dailyTotals[expenseDate] ?? 0) + expense.amount;
    }

    final averageDaily = totalAmount / 7;
    final topCategory = categoryBreakdown.isNotEmpty
        ? categoryBreakdown.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;

    final highestSpendingDay = dailyTotals.isNotEmpty
        ? dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return WeeklyReport(
      startDate: startDate,
      endDate: endDate,
      expenses: weekExpenses,
      totalAmount: totalAmount,
      averageDaily: averageDaily,
      categoryBreakdown: categoryBreakdown,
      categoryCount: categoryCount,
      dailyTotals: dailyTotals,
      topCategory: topCategory,
      highestSpendingDay: highestSpendingDay,
      expenseCount: weekExpenses.length,
    );
  }

  Future<MonthlyReport> generateMonthlyReport(
      List<Expense> expenses, DateTime month) async {
    final monthExpenses = expenses.where((expense) {
      return expense.date.year == month.year &&
          expense.date.month == month.month;
    }).toList();

    final totalAmount =
        monthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categoryBreakdown = <String, double>{};
    final weeklyTotals = <int, double>{};
    final categoryCount = <String, int>{};

    for (final expense in monthExpenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] =
          (categoryCount[expense.category] ?? 0) + 1;

      final weekOfMonth = ((expense.date.day - 1) / 7).floor() + 1;
      weeklyTotals[weekOfMonth] =
          (weeklyTotals[weekOfMonth] ?? 0) + expense.amount;
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final averageDaily = totalAmount / daysInMonth;
    final topCategory = categoryBreakdown.isNotEmpty
        ? categoryBreakdown.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;

    return MonthlyReport(
      month: month,
      expenses: monthExpenses,
      totalAmount: totalAmount,
      averageDaily: averageDaily,
      categoryBreakdown: categoryBreakdown,
      categoryCount: categoryCount,
      weeklyTotals: weeklyTotals,
      topCategory: topCategory,
      expenseCount: monthExpenses.length,
      daysInMonth: daysInMonth,
    );
  }

  Future<void> scheduleAutomaticReports({
    bool enableDaily = true,
    bool enableWeekly = true,
    int dailyHour = 20,
    int dailyMinute = 0,
    int weeklyDay = 7, // Sunday
    int weeklyHour = 10,
    int weeklyMinute = 0,
  }) async {
    if (enableDaily) {
      await _notificationService.scheduleDailyReminder(
        hour: dailyHour,
        minute: dailyMinute,
        title: 'Daily Expense Summary',
        body: 'Your daily spending report is ready to view!',
      );
    }

    if (enableWeekly) {
      await _notificationService.scheduleWeeklyReport(
        weekday: weeklyDay,
        hour: weeklyHour,
        minute: weeklyMinute,
        title: 'Weekly Expense Report',
        body: 'Your weekly spending summary is ready!',
      );
    }
  }

  Future<String> exportReportAsPdf(dynamic report) async {
    // This would require a PDF generation library like pdf or printing
    // For now, we'll export as formatted text
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');

    String content = _formatReportAsText(report);
    await file.writeAsString(content);

    return file.path;
  }

  Future<void> shareReport(dynamic report) async {
    final filePath = await exportReportAsPdf(report);
    final xFile = XFile(filePath);

    String reportType = report is DailyReport
        ? 'Daily'
        : report is WeeklyReport
            ? 'Weekly'
            : 'Monthly';

    await Share.shareXFiles(
      [xFile],
      text: '$reportType Expense Report',
      subject:
          '$reportType Expense Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  String _formatReportAsText(dynamic report) {
    final buffer = StringBuffer();
    final currency = _currencyService.selectedCurrency;
    final symbol = _currencyService.getCurrencySymbol(currency);

    if (report is DailyReport) {
      buffer.writeln('DAILY EXPENSE REPORT');
      buffer.writeln('Date: ${DateFormat('yyyy-MM-dd').format(report.date)}');
      buffer.writeln('=' * 50);
      buffer.writeln('Total Expenses: ${report.expenseCount}');
      buffer.writeln(
          'Total Amount: $symbol${report.totalAmount.toStringAsFixed(2)}');

      if (report.topCategory != null) {
        buffer.writeln('Top Category: ${report.topCategory}');
      }

      buffer.writeln('\nCategory Breakdown:');
      report.categoryBreakdown.forEach((category, amount) {
        final percentage =
            (amount / report.totalAmount * 100).toStringAsFixed(1);
        buffer.writeln(
            '  $category: $symbol${amount.toStringAsFixed(2)} ($percentage%)');
      });

      buffer.writeln('\nExpense Details:');
      for (final expense in report.expenses) {
        buffer.writeln(
            '  • ${expense.title}: $symbol${expense.amount.toStringAsFixed(2)} (${expense.category})');
      }
    } else if (report is WeeklyReport) {
      buffer.writeln('WEEKLY EXPENSE REPORT');
      buffer.writeln(
          'Period: ${DateFormat('yyyy-MM-dd').format(report.startDate)} to ${DateFormat('yyyy-MM-dd').format(report.endDate)}');
      buffer.writeln('=' * 50);
      buffer.writeln('Total Expenses: ${report.expenseCount}');
      buffer.writeln(
          'Total Amount: $symbol${report.totalAmount.toStringAsFixed(2)}');
      buffer.writeln(
          'Daily Average: $symbol${report.averageDaily.toStringAsFixed(2)}');

      if (report.topCategory != null) {
        buffer.writeln('Top Category: ${report.topCategory}');
      }

      if (report.highestSpendingDay != null) {
        buffer.writeln(
            'Highest Spending Day: ${DateFormat('yyyy-MM-dd').format(report.highestSpendingDay!)}');
      }

      buffer.writeln('\nCategory Breakdown:');
      report.categoryBreakdown.forEach((category, amount) {
        final percentage =
            (amount / report.totalAmount * 100).toStringAsFixed(1);
        buffer.writeln(
            '  $category: $symbol${amount.toStringAsFixed(2)} ($percentage%)');
      });

      buffer.writeln('\nDaily Totals:');
      report.dailyTotals.forEach((date, amount) {
        buffer.writeln(
            '  ${DateFormat('yyyy-MM-dd').format(date)}: $symbol${amount.toStringAsFixed(2)}');
      });
    } else if (report is MonthlyReport) {
      buffer.writeln('MONTHLY EXPENSE REPORT');
      buffer.writeln('Month: ${DateFormat('MMMM yyyy').format(report.month)}');
      buffer.writeln('=' * 50);
      buffer.writeln('Total Expenses: ${report.expenseCount}');
      buffer.writeln(
          'Total Amount: $symbol${report.totalAmount.toStringAsFixed(2)}');
      buffer.writeln(
          'Daily Average: $symbol${report.averageDaily.toStringAsFixed(2)}');

      if (report.topCategory != null) {
        buffer.writeln('Top Category: ${report.topCategory}');
      }

      buffer.writeln('\nCategory Breakdown:');
      report.categoryBreakdown.forEach((category, amount) {
        final percentage =
            (amount / report.totalAmount * 100).toStringAsFixed(1);
        buffer.writeln(
            '  $category: $symbol${amount.toStringAsFixed(2)} ($percentage%)');
      });

      buffer.writeln('\nWeekly Totals:');
      report.weeklyTotals.forEach((week, amount) {
        buffer.writeln('  Week $week: $symbol${amount.toStringAsFixed(2)}');
      });
    }

    buffer.writeln('\n' + '=' * 50);
    buffer.writeln(
        'Report generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');

    return buffer.toString();
  }
}

// Report data classes
class DailyReport {
  final DateTime date;
  final List<Expense> expenses;
  final double totalAmount;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryCount;
  final String? topCategory;
  final int expenseCount;

  DailyReport({
    required this.date,
    required this.expenses,
    required this.totalAmount,
    required this.categoryBreakdown,
    required this.categoryCount,
    this.topCategory,
    required this.expenseCount,
  });
}

class WeeklyReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<Expense> expenses;
  final double totalAmount;
  final double averageDaily;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryCount;
  final Map<DateTime, double> dailyTotals;
  final String? topCategory;
  final DateTime? highestSpendingDay;
  final int expenseCount;

  WeeklyReport({
    required this.startDate,
    required this.endDate,
    required this.expenses,
    required this.totalAmount,
    required this.averageDaily,
    required this.categoryBreakdown,
    required this.categoryCount,
    required this.dailyTotals,
    this.topCategory,
    this.highestSpendingDay,
    required this.expenseCount,
  });
}

class MonthlyReport {
  final DateTime month;
  final List<Expense> expenses;
  final double totalAmount;
  final double averageDaily;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryCount;
  final Map<int, double> weeklyTotals;
  final String? topCategory;
  final int expenseCount;
  final int daysInMonth;

  MonthlyReport({
    required this.month,
    required this.expenses,
    required this.totalAmount,
    required this.averageDaily,
    required this.categoryBreakdown,
    required this.categoryCount,
    required this.weeklyTotals,
    this.topCategory,
    required this.expenseCount,
    required this.daysInMonth,
  });
}
