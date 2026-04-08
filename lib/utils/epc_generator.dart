import 'dart:math';

class EpcGenerator {
  /// Generates a valid 24-character hexadecimal string for an RFID EPC.
  /// It uses characters 0-9 and A-F.
  static String generateRandomEpc() {
    final random = Random();
    const String hexChars = '0123456789ABCDEF';

    // Generate exactly 24 characters (96 bits)
    String newEpc = '';
    for (int i = 0; i < 24; i++) {
      newEpc += hexChars[random.nextInt(hexChars.length)];
    }

    return newEpc;
  }
}