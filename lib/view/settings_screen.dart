import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../view_model/expense_view_model.dart';
import '../model/expense.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'INR';
  bool _isExporting = false;

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
      // Create CSV data
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

      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Write the CSV data to file
      await file.writeAsString(csvData);

      // Share the file
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
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
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
    // Use vm.allExpenses which is the getter for all expenses (not filtered)
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
            child: const Text(
              'Export & Share',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ExpenseViewModel>(context);
    // Use vm.allExpenses which is the getter for all expenses (not filtered)
    final allExpensesList = vm.allExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export CSV Section
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.file_download,
                  color: Colors.green,
                ),
              ),
              title: const Text(
                'Export Expenses as CSV',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${allExpensesList.length} expenses available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
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

          // Currency Selection
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Select Currency',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Current: $_currency',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select Currency',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...['INR', 'USD', 'EUR', 'JPY', 'GBP'].map(
                          (currency) => ListTile(
                            title: Text(
                              currency,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: _currency == currency
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() => _currency = currency);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                  _buildInfoRow('Total Expenses', '${allExpensesList.length}'),
                  _buildInfoRow('Font Family', 'Inter'),
                ],
              ),
            ),
          ),
        ],
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
}
