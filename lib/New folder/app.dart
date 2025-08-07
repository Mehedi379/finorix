import 'package:flutter/material.dart';
import 'view/home_screen.dart';
import 'view/add_expense_screen.dart';
import 'view/analytics_screen.dart';
import 'view/settings_screen.dart';

class TrackDailyFinancesApp extends StatelessWidget {
  const TrackDailyFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track Daily Finances',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/add': (_) => const AddExpenseScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
