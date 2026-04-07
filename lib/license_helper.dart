// File: lib/license_helper.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseHelper {
  // This points to the standard public Downloads folder on 99% of Android PDAs
  // The dot (.) in front makes the file invisible to normal file managers!
  static const String _licenseFilePath = '/storage/emulated/0/Download/.pda_license.txt';

  // --- SAVE THE LICENSE ---
  static Future<void> saveLicense(String mode) async {
    // 1. Save to standard SharedPreferences (for fast everyday loading)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appMode', mode);

    // 2. Ask for permission and secretly save to the public folder
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      try {
        final file = File(_licenseFilePath);
        await file.writeAsString(mode);
      } catch (e) {
        print("Error saving hidden license: $e");
      }
    }
  }

  // --- READ THE LICENSE ---
  static Future<String?> getLicense() async {
    // 1. Check SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    String? mode = prefs.getString('appMode');

    if (mode != null && mode.isNotEmpty) {
      return mode; // Everything is normal, return the mode
    }

    // 2. IF WE ARE HERE, THE DATA WAS WIPED! Let's check our hidden file.
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      try {
        final file = File(_licenseFilePath);
        if (await file.exists()) {
          mode = await file.readAsString();

          // 3. Restore the wiped SharedPreferences so it loads fast next time!
          if (mode.isNotEmpty) {
            await prefs.setString('appMode', mode);
            return mode;
          }
        }
      } catch (e) {
        print("Error reading hidden license: $e");
      }
    }

    return null; // First time install, or completely brand new device
  }
}