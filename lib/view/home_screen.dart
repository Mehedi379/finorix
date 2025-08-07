import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/expense_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/add');
        break;
      case 2:
        Navigator.pushNamed(context, '/analytics');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        break;
    }
  }

  Widget _buildHomeView() {
    final vm = Provider.of<ExpenseViewModel>(context);
    if (vm.expenses.isEmpty) {
      return const Center(child: Text('No expenses yet'));
    }

    return ListView.builder(
      itemCount: vm.expenses.length,
      itemBuilder: (context, index) {
        final expense = vm.expenses[index];
        return Dismissible(
          key: Key(expense.id),
          onDismissed: (_) => vm.deleteExpense(expense.id),
          background: Container(color: Colors.red),
          child: ListTile(
            title: Text(expense.title),
            subtitle: Text(
              '${expense.category} - ${expense.date.toLocal().toString().split(' ')[0]}',
            ),
            trailing: Text('₹${expense.amount.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Daily Finances')),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex == 0 ? 0 : -1,
          children: [
            _buildHomeView(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
