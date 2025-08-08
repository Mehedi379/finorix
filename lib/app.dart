// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'services/auth_service.dart';
// import 'view/home_screen.dart';
// import 'view/enhanced_add_expense_screen.dart';
// import 'view/analytics_screen.dart';
// import 'view/enhanced_settings_screen.dart';
// import 'view/auth_screen.dart';

// class TrackDailyFinancesApp extends StatelessWidget {
//   const TrackDailyFinancesApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Finorix - Smart Expense Tracker',
//       theme: ThemeData(
//         brightness: Brightness.light,
//         primarySwatch: Colors.green,
//         useMaterial3: true,
//         fontFamily: 'Inter',
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.green,
//           brightness: Brightness.light,
//         ),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           centerTitle: true,
//         ),
//         cardTheme: CardTheme(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             elevation: 2,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         fontFamily: 'Inter',
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.green,
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: true,
//         ),
//         cardTheme: CardTheme(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             elevation: 2,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       home: Consumer<AuthService>(
//         builder: (context, authService, child) {
//           // Show loading screen while checking auth state
//           if (authService.isLoading) {
//             return const Scaffold(
//               body: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }

//           // Show auth screen if not authenticated
//           if (!authService.isAuthenticated) {
//             return const AuthScreen();
//           }

//           // Show main app if authenticated
//           return const HomeScreen();
//         },
//       ),
//       routes: {
//         '/auth': (_) => const AuthScreen(),
//         '/home': (_) => const HomeScreen(),
//         '/add': (_) => const EnhancedAddExpenseScreen(),
//         '/analytics': (_) => const AnalyticsScreen(),
//         '/settings': (_) => const EnhancedSettingsScreen(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'view/home_screen.dart';
import 'view/enhanced_add_expense_screen.dart';
import 'view/analytics_screen.dart';
import 'view/enhanced_settings_screen.dart';
import 'view/auth_screen.dart';

class TrackDailyFinancesApp extends StatelessWidget {
  const TrackDailyFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finorix - Smart Expense Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          print(
              'AuthService state: isInitializing=${authService.isInitializing}, isAuthenticated=${authService.isAuthenticated}, isLoading=${authService.isLoading}');

          // Show loading screen while initializing auth or during auth operations
          if (authService.isInitializing) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing...'),
                  ],
                ),
              ),
            );
          }

          // Show auth screen if not authenticated
          if (!authService.isAuthenticated) {
            print('Showing auth screen - user not authenticated');
            return const AuthScreen();
          }

          // Show main app if authenticated
          print(
              'Showing home screen - user authenticated: ${authService.currentUser?.uid}');
          return const HomeScreen();
        },
      ),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/add': (_) => const EnhancedAddExpenseScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/settings': (_) => const EnhancedSettingsScreen(),
      },
    );
  }
}
