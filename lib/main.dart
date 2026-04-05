// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Needed for saving preferences

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/simple_home_screen.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart'; // <-- Import the new Splash Screen

// 1. main() is now 'async' so we can check SharedPreferences before the app loads
void main() async {
  // Ensure Flutter engine is fully initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check if the user previously selected a mode
  final prefs = await SharedPreferences.getInstance();
  final bool? isSimpleMode = prefs.getBool('isSimpleMode');

  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      // 3. Pass the saved preference into MyApp
      child: MyApp(initialIsSimpleMode: isSimpleMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool? initialIsSimpleMode; // <-- Variable to hold the starting mode

  const MyApp({super.key, this.initialIsSimpleMode});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    // --- 1. PREMIUM LOGIC ---
    // Figure out where the user is supposed to go after the splash screen
    Widget startScreen;
    if (initialIsSimpleMode == false) {
      startScreen = const HomeScreen();
    } else {
      startScreen = const SimpleHomeScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('ar', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A00E0)),
        useMaterial3: true,
      ),
      // --- 2. SHOW SPLASH SCREEN FIRST ---
      // We pass the startScreen to the splash screen so it knows where to go next!
      home: SplashScreen(nextScreen: startScreen),
    );
  }
}