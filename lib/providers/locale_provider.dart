import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // English is our default language
  Locale _locale = const Locale('en', '');

  // A getter so other screens can read the current locale
  Locale get locale => _locale;

  LocaleProvider() {
    // When the provider is created, immediately load the saved language
    _loadSavedLocale();
  }

  // This is the function we'll call from the HomeScreen dropdown
  void setLocale(Locale newLocale) async {
    if (!['en', 'fr', 'ar'].contains(newLocale.languageCode)) return;

    _locale = newLocale;
    notifyListeners(); // Tells the whole app to rebuild with the new language!

    // Save the choice to the device storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  // Helper function to read from device storage on startup
  void _loadSavedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('language_code');

    if (savedLanguage != null) {
      _locale = Locale(savedLanguage, '');
      notifyListeners();
    }
  }
}