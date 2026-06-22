import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/category_item.dart';
import 'models/transaction.dart';
import 'providers/expense_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  // Ensure flutter is ready before doing async stuff
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive Database
  await Hive.initFlutter();

  // 2. Register our Transaction Adapter (created by the generator)
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryItemAdapter());

  // 3. Open the box (like opening a specific table in a database)
  await Hive.openBox<Transaction>('transactionsBox');
  await Hive.openBox<CategoryItem>('categoriesBox');

  // Wrap the app in our Provider so it can manage state
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider()
        ..loadTransactions()
        ..loadCategories(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,

      // 1. LIGHT THEME (Follows system)
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green, // A nice financial green accent
        useMaterial3: true,
        // Force iOS sliding page transitions on all platforms
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // 2. DARK THEME (Follows system)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        // Force iOS sliding page transitions on all platforms
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // Automatically switch between light and dark based on phone settings
      themeMode: ThemeMode.system,

      // Applies iOS bouncy scrolling to all scrollable areas in the app
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          child: child!,
        );
      },

      home: const MainScreen(), // We will create this next!
    );
  }
}
