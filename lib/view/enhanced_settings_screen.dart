import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../view_model/expense_view_model.dart';
import '../model/expense.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  bool _isExporting = false;
  bool _dailyReminderEnabled = false;
  bool _weeklyReportEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _weeklyReportDay = 7; // Sunday
  TimeOfDay _weeklyReportTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    // Load notification settings from shared preferences
    // This is a simplified version - in production you'd want to persist these settings
    setState(() {
      // Default values loaded
    });
  }

  Future<void> _exportCSV(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final rows = [
        ['Title', 'Amount', 'Category', 'Date'],
        ...expenses.map((e) => [
              e.title,
              e.amount.toString(),
              e.category,
              '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}'
            ])
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'My Expense Report - ${expenses.length} expenses',
        subject: 'Expense Report CSV',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'CSV exported successfully! (${expenses.length} expenses)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportDialog(ExpenseViewModel vm) {
    final allExpensesList = vm.allExpenses;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Export Expenses',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export ${allExpensesList.length} expenses to CSV file',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'The CSV file will contain:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Title\n• Amount\n• Category\n• Date'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportCSV(allExpensesList);
            },
            child: const Text('Export & Share'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<CurrencyService>(
        builder: (context, currencyService, child) => AlertDialog(
          title: const Text(
            'Select Currency',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currencyService.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                if (currencyService.lastUpdate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Last updated: ${currencyService.lastUpdate!.toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currencyService.availableCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency =
                          currencyService.availableCurrencies[index];
                      final symbol =
                          currencyService.getCurrencySymbol(currency);
                      final isSelected =
                          currency == currencyService.selectedCurrency;

                      return ListTile(
                        leading: Text(
                          symbol,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(currency),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () async {
                          await currencyService.setSelectedCurrency(currency);
                          if (mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: currencyService.isLoading
                  ? null
                  : () async {
                      await currencyService.updateExchangeRates();
                    },
              child: const Text('Update Rates'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Notification Settings',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Reminder Settings
                const Text(
                  'Daily Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SwitchListTile(
                  title: const Text('Enable Daily Reminder'),
                  subtitle: Text(_dailyReminderEnabled
                      ? 'Remind me at ${_dailyReminderTime.format(context)}'
                      : 'Disabled'),
                  value: _dailyReminderEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _dailyReminderEnabled = value;
                    });
                  },
                ),
                if (_dailyReminderEnabled)
                  ListTile(
                    title: const Text('Reminder Time'),
                    subtitle: Text(_dailyReminderTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _dailyReminderTime,
                      );
                      if (time != null) {
                        setDialogState(() {
                          _dailyReminderTime = time;
                        });
                      }
                    },
                  ),

                const Divider(),

                // Weekly Report Settings
                const Text(
                  'Weekly Report',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SwitchListTile(
                  title: const Text('Enable Weekly Report'),
                  subtitle: Text(_weeklyReportEnabled
                      ? 'Every ${_getWeekdayName(_weeklyReportDay)} at ${_weeklyReportTime.format(context)}'
                      : 'Disabled'),
                  value: _weeklyReportEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _weeklyReportEnabled = value;
                    });
                  },
                ),
                if (_weeklyReportEnabled) ...[
                  ListTile(
                    title: const Text('Report Day'),
                    subtitle: Text(_getWeekdayName(_weeklyReportDay)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Day'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 1; i <= 7; i++)
                                ListTile(
                                  title: Text(_getWeekdayName(i)),
                                  trailing: _weeklyReportDay == i
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    setDialogState(() {
                                      _weeklyReportDay = i;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Report Time'),
                    subtitle: Text(_weeklyReportTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _weeklyReportTime,
                      );
                      if (time != null) {
                        setDialogState(() {
                          _weeklyReportTime = time;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveNotificationSettings();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    final vm = Provider.of<ExpenseViewModel>(context, listen: false);

    await vm.setDailyReminder(
      enabled: _dailyReminderEnabled,
      hour: _dailyReminderTime.hour,
      minute: _dailyReminderTime.minute,
    );

    await vm.setWeeklyReport(
      enabled: _weeklyReportEnabled,
      weekday: _weeklyReportDay,
      hour: _weeklyReportTime.hour,
      minute: _weeklyReportTime.minute,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer<ExpenseViewModel>(
        builder: (context, vm, child) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Generate Reports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Daily Report
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text('Daily Report'),
                subtitle: const Text('Generate today\'s expense report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final report = await vm.generateDailyReport(DateTime.now());
                  await vm.shareReport(report);
                },
              ),

              // Weekly Report
              ListTile(
                leading: const Icon(Icons.view_week, color: Colors.green),
                title: const Text('Weekly Report'),
                subtitle: const Text('Generate this week\'s expense report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final now = DateTime.now();
                  final startOfWeek =
                      now.subtract(Duration(days: now.weekday - 1));
                  final report = await vm.generateWeeklyReport(startOfWeek);
                  await vm.shareReport(report);
                },
              ),

              // Monthly Report
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.orange),
                title: const Text('Monthly Report'),
                subtitle: const Text('Generate this month\'s expense report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final now = DateTime.now();
                  final report = await vm.generateMonthlyReport(now);
                  await vm.shareReport(report);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: Consumer3<ExpenseViewModel, AuthService, CurrencyService>(
        builder: (context, vm, authService, currencyService, child) {
          final allExpensesList = vm.allExpenses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Account Section
              if (authService.isAuthenticated) ...[
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: const Text(
                      'Account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      authService.currentUser?.email ?? 'Anonymous User',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: vm.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.cloud_sync),
                            onPressed: vm.syncToCloud,
                            tooltip: 'Sync to Cloud',
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Export CSV Section
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_download, color: Colors.green),
                  ),
                  title: const Text(
                    'Export Expenses as CSV',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${allExpensesList.length} expenses available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : () => _showExportDialog(vm),
                ),
              ),

              const SizedBox(height: 16),

              // Reports Section
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assessment, color: Colors.orange),
                  ),
                  title: const Text(
                    'Generate Reports',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Daily, weekly, and monthly reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showReportOptions,
                ),
              ),

              const SizedBox(height: 16),

              // Currency Selection
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.currency_exchange,
                        color: Colors.purple),
                  ),
                  title: const Text(
                    'Currency Settings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Current: ${currencyService.selectedCurrency}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currencyService.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _showCurrencyDialog,
                ),
              ),

              const SizedBox(height: 16),

              // Notifications Section
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.red),
                  ),
                  title: const Text(
                    'Notifications & Reminders',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      const Text('Set up daily reminders and weekly reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showNotificationSettings,
                ),
              ),

              const SizedBox(height: 24),

              // App Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Version', '1.0.0'),
                      _buildInfoRow(
                          'Total Expenses', '${allExpensesList.length}'),
                      _buildInfoRow(
                          'Currency', currencyService.selectedCurrency),
                      _buildInfoRow('Font Family', 'Inter'),
                      if (currencyService.lastUpdate != null)
                        _buildInfoRow(
                          'Exchange Rates Updated',
                          currencyService.lastUpdate!.toString().split(' ')[0],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Out Button (if authenticated)
              if (authService.isAuthenticated)
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () async {
                      await authService.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/auth');
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
