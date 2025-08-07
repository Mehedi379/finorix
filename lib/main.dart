// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// // import 'view/home_screen.dart';
// import 'view/add_expense_screen.dart';
// import 'view/analytics_screen.dart';
// import 'view/settings_screen.dart';
// import 'view_model/expense_view_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';

// // import '../view_model/expense_view_model.dart';
// // import '../model/expense.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   final List<Widget> _screens = [
//     const ExpenseListScreen(),
//     const AddExpenseScreen(),
//     const AnalyticsScreen(),
//     const SettingsScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
//           BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Stats'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }

// class ExpenseListScreen extends StatelessWidget {
//   const ExpenseListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<ExpenseViewModel>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Track Daily Finances')),
//       body: vm.expenses.isEmpty
//           ? const Center(child: Text('No expenses yet'))
//           : ListView.builder(
//               itemCount: vm.expenses.length,
//               itemBuilder: (context, index) {
//                 final expense = vm.expenses[index];
//                 return Dismissible(
//                   key: Key(expense.id),
//                   onDismissed: (_) => vm.deleteExpense(expense.id),
//                   background: Container(color: Colors.red),
//                   child: ListTile(
//                     title: Text(expense.title),
//                     subtitle: Text(
//                       '${expense.category} - ${expense.date.toLocal().toString().split(' ')[0]}',
//                     ),
//                     trailing: Text('₹${expense.amount.toStringAsFixed(2)}'),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'view/home_screen.dart';
// // import 'view_model/expense_view_model.dart';

// // void main() {
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ChangeNotifierProvider(
// //       create: (_) => ExpenseViewModel(),
// //       child: MaterialApp(
// //         debugShowCheckedModeBanner: false,
// //         title: 'Track Daily Finances',
// //         theme: ThemeData(
// //           primarySwatch: Colors.blue,
// //         ),
// //         home: const HomeScreen(),
// //       ),
// //     );
// //   }
// // }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_model/expense_view_model.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseViewModel(),
      child: const TrackDailyFinancesApp(),
    );
  }
}
