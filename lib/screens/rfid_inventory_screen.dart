// File: lib/screens/rfid_inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_db_helper.dart';

class RfidInventoryScreen extends StatefulWidget {
  const RfidInventoryScreen({super.key});

  @override
  State<RfidInventoryScreen> createState() => _RfidInventoryScreenState();
}

class _RfidInventoryScreenState extends State<RfidInventoryScreen> {
  bool _isLoading = true;
  int _totalEpcs = 0;

  // This Map will group our tags.
  // The Key is the "Date/Time", the Value is the List of EPCs scanned then.
  Map<String, List<String>> _groupedSessions = {};

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final List<Map<String, dynamic>> rawTags = await AppDatabaseHelper.instance.getSavedScannedTags();

    Map<String, List<String>> grouped = {};
    int totalCount = 0;

    for (var row in rawTags) {
      String epc = row['epc'] as String;
      // If it's an old tag without a time, default to 'Unknown Time'
      String timeStr = row['scanTime'] as String? ?? '';

      String sessionTitle = "Legacy Scans (No Time)";
      if (timeStr.isNotEmpty) {
        DateTime dt = DateTime.parse(timeStr);
        // Format string to look like: "2026-04-07 at 14:30"
        String date = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
        String time = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
        sessionTitle = "$date  at  $time";
      }

      // Add the tag to its specific date/time group!
      if (!grouped.containsKey(sessionTitle)) {
        grouped[sessionTitle] = [];
      }
      grouped[sessionTitle]!.add(epc);
      totalCount++;
    }

    setState(() {
      _groupedSessions = grouped;
      _totalEpcs = totalCount;
      _isLoading = false;
    });
  }

  Future<void> _clearData() async {
    await AppDatabaseHelper.instance.clearScannedTags();
    _loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    // We get the session keys to build our list
    List<String> sessionKeys = _groupedSessions.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Scan Sessions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E0045),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash),
            tooltip: 'Clear All Tags',
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Clear Tag Database?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    content: Text("This will delete all saved EPC tags from the isolated database.", style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins())),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearData();
                        },
                        child: Text("Clear", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : Column(
        children: [
          _buildDashboard(),
          Expanded(
            child: _groupedSessions.isEmpty
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.tag, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No tags in database.', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Scan and save tags to see them here.', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14)),
                  ],
                )
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessionKeys.length,
              itemBuilder: (context, index) {
                String sessionDate = sessionKeys[index];
                List<String> epcsInSession = _groupedSessions[sessionDate]!;
                return _buildSessionCard(sessionDate, epcsInSession);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP DASHBOARD WIDGET ---
  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Scanned (All Sessions)', _totalEpcs, const Color(0xFF4A00E0)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- GROUPED SESSION CARD WIDGET ---
  Widget _buildSessionCard(String sessionDate, List<String> epcs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF4A00E0).withOpacity(0.3), width: 1)
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Ensures the background color doesn't leak out
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: const Icon(CupertinoIcons.calendar, color: Color(0xFF4A00E0), size: 30),
        title: Text(
            sessionDate,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Text(
            "${epcs.length} tags scanned",
            style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)
        ),
        // These are the individual EPC items inside the dropdown
        children: epcs.map((epc) {
          return Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))
            ),
            child: ListTile(
              leading: const Icon(CupertinoIcons.tag_solid, color: Colors.grey, size: 20),
              title: Text(epc, style: GoogleFonts.poppins(fontSize: 13, letterSpacing: 1.0)),
              trailing: const Icon(Icons.check, color: Colors.green, size: 16),
            ),
          );
        }).toList(),
      ),
    );
  }
}