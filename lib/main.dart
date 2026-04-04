import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <-- New import for Provider
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'providers/locale_provider.dart'; // <-- New import for your LocaleProvider

void main() {
  runApp(
    // 1. We wrap the entire app in a ChangeNotifierProvider.
    // This makes the LocaleProvider available to every single screen in your app!
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

// 2. MyApp is back to being a clean, simple StatelessWidget!
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. We listen to the LocaleProvider. Whenever it calls notifyListeners()
    // (like when a user selects a new language), this widget will rebuild
    // and update the language everywhere.
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      // 4. We read the current locale directly from the provider
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
      // 5. Look how clean this is now! No more passing the _changeLanguage
      // function through the constructor.
      home: const HomeScreen(),
    );
  }
}