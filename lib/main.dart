import 'package:flutter/material.dart';

void main() async {
  // Ensure flutter bindings are initialized before doing any async work
  WidgetsFlutterBinding.ensureInitialized();

  // We will initialize our local database here later

  runApp(const MyApp());
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

      home: const HomeScreen(), // We will create this next!
    );
  }
}

// A temporary placeholder for our Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Expenses')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No expenses yet!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Testing the iOS page transition
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondScreen()),
                );
              },
              child: const Text('Test iOS Transition'),
            ),
          ],
        ),
      ),
    );
  }
}

// A temporary second screen to test the animation
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: const Center(
        child: Text('Notice how this slid in from the right?'),
      ),
    );
  }
}
