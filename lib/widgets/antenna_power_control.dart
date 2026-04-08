// File: lib/widgets/antenna_power_control.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AntennaPowerControl extends StatefulWidget {
  const AntennaPowerControl({super.key});

  @override
  State<AntennaPowerControl> createState() => _AntennaPowerControlState();
}

class _AntennaPowerControlState extends State<AntennaPowerControl> {
  // Talks to your MainActivity.kt!
  static const MethodChannel _methodChannel = MethodChannel('com.pda_inventory/rfid_methods');

  // Bluebird hardware standard max is 30 dBm, min is usually 5 dBm
  double _currentPower = 30.0;
  bool _isUpdating = false;

  Future<void> _updateAntennaPower(double newPower) async {
    setState(() => _isUpdating = true);

    try {
      await _methodChannel.invokeMethod('setTxPower', {"power": newPower.toInt()});
      setState(() => _currentPower = newPower);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Antenna range set to ${newPower.toInt()} dBm', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to set power: '${e.message}'.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update range.', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cell_tower, color: Color(0xFF4A00E0)),
                    const SizedBox(width: 8),
                    Text(
                      "Scanner Range Control",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                _isUpdating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                  "${_currentPower.toInt()} dBm",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF4A00E0), fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getPowerDescription(_currentPower),
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4A00E0),
                inactiveTrackColor: const Color(0xFF4A00E0).withOpacity(0.2),
                thumbColor: const Color(0xFF4A00E0),
                overlayColor: const Color(0xFF4A00E0).withOpacity(0.1),
                valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white),
              ),
              child: Slider(
                value: _currentPower,
                min: 5.0,
                max: 30.0,
                divisions: 25,
                label: _currentPower.round().toString(),
                onChangeEnd: (value) {
                  // Only communicate with hardware when the user STOPS dragging to avoid spamming the serial port
                  _updateAntennaPower(value);
                },
                onChanged: (value) {
                  setState(() => _currentPower = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPowerDescription(double power) {
    if (power <= 10) return "Point-of-Sale (Very Close)";
    if (power <= 15) return "Single Table (Short Range)";
    if (power <= 22) return "Specific Rack (Medium Range)";
    return "Backroom Sweep (Maximum Range)";
  }
}