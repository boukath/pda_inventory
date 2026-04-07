// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/simple_home_screen.dart';
import 'screens/rfid_dashboard_screen.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'license_helper.dart'; // <-- Import the new hidden file helper

// 1. main() is async so we can check the LicenseHelper before the app loads
void main() async {
  // Ensure Flutter engine is fully initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // 2. CHECK THE HIDDEN LICENSE
  // This automatically checks standard SharedPreferences first,
  // and if it was wiped, it magically restores it from the hidden folder!
  final String? savedMode = await LicenseHelper.getLicense();

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
      // If nothing is saved (e.g., brand new physical device), show Mode Selection Screen
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