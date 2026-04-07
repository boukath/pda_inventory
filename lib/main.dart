// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Needed for saving preferences

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/simple_home_screen.dart';
import 'screens/rfid_dashboard_screen.dart'; // <-- Import the new RFID Dashboard Screen
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart'; // <-- Import the Splash Screen

// 1. main() is async so we can check SharedPreferences before the app loads
void main() async {
  // Ensure Flutter engine is fully initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check if the user previously selected a mode
  final prefs = await SharedPreferences.getInstance();
  // Fetch the string 'appMode' instead of the boolean 'isSimpleMode'
  final String? savedMode = prefs.getString('appMode');

  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      // 3. Pass the saved string preference into MyApp
      child: MyApp(initialMode: savedMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialMode; // <-- Variable to hold the starting mode string

  const MyApp({super.key, this.initialMode});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    // --- 1. PREMIUM LOGIC ---
    // Figure out where the user is supposed to go after the splash screen
    Widget startScreen;
    if (initialMode == 'simple') {
      startScreen = const SimpleHomeScreen();
    } else if (initialMode == 'rfid') {
      startScreen = const RfidDashboardScreen();
    } else if (initialMode == 'advanced') {
      startScreen = const HomeScreen();
    } else {
      // If nothing is saved (e.g., first install), show Mode Selection Screen
      startScreen = const ModeSelectionScreen();
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