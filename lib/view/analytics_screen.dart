// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:pie_chart/pie_chart.dart';
// // import '../view_model/expense_view_model.dart';

// // class AnalyticsScreen extends StatelessWidget {
// //   const AnalyticsScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final vm = Provider.of<ExpenseViewModel>(context);
// //     final Map<String, double> dataMap = {};

// //     for (var e in vm.expenses) {
// //       dataMap[e.category] = (dataMap[e.category] ?? 0) + e.amount;
// //     }

// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Analytics')),
// //       body: Center(
// //         child: dataMap.isEmpty
// //             ? const Text('No data to display')
// //             : Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: PieChart(
// //                   dataMap: dataMap,
// //                   chartRadius: MediaQuery.of(context).size.width / 2,
// //                   chartValuesOptions: const ChartValuesOptions(
// //                     showChartValuesInPercentage: true,
// //                   ),
// //                 ),
// //               ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pie_chart/pie_chart.dart';
// import '../view_model/expense_view_model.dart';

// class AnalyticsScreen extends StatelessWidget {
//   const AnalyticsScreen({super.key});

//   Color _getCategoryColor(String category) {
//     switch (category.toLowerCase()) {
//       case 'food':
//         return Colors.orange;
//       case 'transport':
//         return Colors.blue;
//       case 'bills':
//         return Colors.red;
//       case 'shopping':
//         return Colors.purple;
//       case 'general':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 32,
//               color: color,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryList(Map<String, double> dataMap, double totalAmount) {
//     final sortedEntries = dataMap.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Category Breakdown',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...sortedEntries.map((entry) {
//               final percentage = ((entry.value / totalAmount) * 100);
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 16,
//                       height: 16,
//                       decoration: BoxDecoration(
//                         color: _getCategoryColor(entry.key),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         entry.key,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           '₹${entry.value.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Text(
//                           '${percentage.toStringAsFixed(1)}%',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<ExpenseViewModel>(context);
//     final expenses = vm.expenses;
    
//     // Calculate category-wise data
//     final Map<String, double> dataMap = {};
//     final Map<String, int> categoryCount = {};
//     double totalAmount = 0;

//     for (var expense in expenses) {
//       dataMap[expense.category] = (dataMap[expense.category] ?? 0) + expense.amount;
//       categoryCount[expense.category] = (categoryCount[expense.category] ?? 0) + 1;
//       totalAmount += expense.amount;
//     }

//     // Create color map for pie chart
//     final Map<String, Color> colorMap = {};
//     for (String category in dataMap.keys) {
//       colorMap[category] = _getCategoryColor(category);
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Analytics',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: expenses.isEmpty
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.pie_chart_outline,
//                       size: 64,
//                       color: Colors.grey[400],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       vm.startDate != null || vm.endDate != null
//                           ? 'No expenses found for selected date range'
//                           : 'No expenses to analyze',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Add some expenses to see analytics',
//                       style: TextStyle(
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             : ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   // Date range info (if applicable)
//                   if (vm.startDate != null && vm.endDate != null)
//                     Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         'Analytics for ${vm.startDate!.day}/${vm.startDate!.month}/${vm.startDate!.year} to ${vm.endDate!.day}/${vm.endDate!.month}/${vm.endDate!.year}',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).primaryColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),

//                   // Summary stats
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildStatCard(
//                           'Total Spent',
//                           '₹${totalAmount.toStringAsFixed(2)}',
//                           Icons.account_balance_wallet,
//                           Colors.red,
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildStatCard(
//                           'Total Expenses',
//                           expenses.length.toString(),
//                           Icons.receipt_long,
//                           Colors.blue,
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildStatCard(
//                           'Categories',
//                           dataMap.length.toString(),
//                           Icons.category,
//                           Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Average per day (if date range is set)
//                   if (vm.startDate != null && vm.endDate != null)
//                     Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.trending_up, color: Colors.orange),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Average per day: ₹${(totalAmount / (vm.endDate!.difference(vm.startDate!).inDays + 1)).toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 16),

//                   // Pie chart
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Expense Distribution',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Center(
//                             child: PieChart(
//                               dataMap: dataMap,
//                               colorList: dataMap.keys.map((k) => colorMap[k]!).toList(),
//                               chartRadius: MediaQuery.of(context).size.width / 2.5,
//                               chartValuesOptions: const ChartValuesOptions(
//                                 showChartValuesInPercentage: true,
//                                 showChartValues: true,
//                                 showChartValuesOutside: false,
//                                 decimalPlaces: 1,
//                               ),
//                               chartLegendSpacing: 32,
//                               legendOptions: const LegendOptions(
//                                 showLegendsInRow: false,
//                                 legendPosition: LegendPosition.bottom,
//                                 showLegends: true,
//                                 legendTextStyle: TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Category breakdown list
//                   _buildCategoryList(dataMap, totalAmount),
//                 ],
//               ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import '../view_model/expense_view_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      case 'shopping':
        return Colors.purple;
      case 'general':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> dataMap, double totalAmount) {
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final percentage = ((entry.value / totalAmount) * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ExpenseViewModel>(context);
    final expenses = vm.expenses; // This uses the filtered expenses

    // Calculate category-wise data
    final Map<String, double> dataMap = {};
    final Map<String, int> categoryCount = {};
    double totalAmount = 0;

    for (var expense in expenses) {
      dataMap[expense.category] =
          (dataMap[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] =
          (categoryCount[expense.category] ?? 0) + 1;
      totalAmount += expense.amount;
    }

    // Create color map for pie chart
    final Map<String, Color> colorMap = {};
    for (String category in dataMap.keys) {
      colorMap[category] = _getCategoryColor(category);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      // Check if date filter is active using the actual getters
                      vm.startDate != null || vm.endDate != null
                          ? 'No expenses found for selected date range'
                          : 'No expenses to analyze',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some expenses to see analytics',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date range info (if applicable)
                  if (vm.startDate != null && vm.endDate != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Analytics for ${vm.startDate!.day}/${vm.startDate!.month}/${vm.startDate!.year} to ${vm.endDate!.day}/${vm.endDate!.month}/${vm.endDate!.year}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Summary stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Spent',
                          '₹${totalAmount.toStringAsFixed(2)}',
                          Icons.account_balance_wallet,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatCard(
                          'Total Expenses',
                          expenses.length.toString(),
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatCard(
                          'Categories',
                          dataMap.length.toString(),
                          Icons.category,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Average per day (if date range is set)
                  if (vm.startDate != null && vm.endDate != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.trending_up, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Average per day: ₹${(totalAmount / (vm.endDate!.difference(vm.startDate!).inDays + 1)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Pie chart
                  if (dataMap.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expense Distribution',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: PieChart(
                                dataMap: dataMap,
                                colorList: dataMap.keys
                                    .map((k) => colorMap[k]!)
                                    .toList(),
                                chartRadius:
                                    MediaQuery.of(context).size.width / 2.5,
                                chartValuesOptions: const ChartValuesOptions(
                                  showChartValuesInPercentage: true,
                                  showChartValues: true,
                                  showChartValuesOutside: false,
                                  decimalPlaces: 1,
                                ),
                                chartLegendSpacing: 32,
                                legendOptions: const LegendOptions(
                                  showLegendsInRow: false,
                                  legendPosition: LegendPosition.bottom,
                                  showLegends: true,
                                  legendTextStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Category breakdown list
                  if (dataMap.isNotEmpty)
                    _buildCategoryList(dataMap, totalAmount),
                ],
              ),
      ),
    );
  }
}
