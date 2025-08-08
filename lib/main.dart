import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view_model/expense_view_model.dart';
import 'services/auth_service.dart';
import 'services/currency_service.dart';
import 'services/voice_service.dart';
import 'services/ocr_service.dart';
import 'services/firebase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<CurrencyService>(
          create: (_) => CurrencyService(),
        ),
        ChangeNotifierProvider<VoiceService>(
          create: (_) => VoiceService(),
        ),
        ChangeNotifierProvider<OCRService>(
          create: (_) => OCRService(),
        ),
        ChangeNotifierProxyProvider<AuthService, ExpenseViewModel>(
          create: (context) => ExpenseViewModel(),
          update: (context, authService, expenseViewModel) =>
              expenseViewModel ?? ExpenseViewModel(),
        ),
      ],
      child: const TrackDailyFinancesApp(),
    );
  }
}
