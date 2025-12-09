// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/access_log_entry.dart';
import '../providers/device_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final List<AccessLogEntry> history = deviceProvider.localHistory;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Access History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF3B30)),
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Clear History',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    content: Text(
                      'This will delete all local history and history on the ESP32 device. This action cannot be undone.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFF3B30).withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                deviceProvider.clearLocalHistory();

                final ipAddress = deviceProvider.deviceIpAddress ?? '';
                if (ipAddress.isNotEmpty) {
                  final success = await ApiService.clearHistoryOnESP(ipAddress);
                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              SizedBox(width: 12),
                              Text('History cleared successfully'),
                            ],
                          ),
                          backgroundColor: Color(0xFF34C759),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to clear history on ESP32.'),
                          backgroundColor: Color(0xFFFF3B30),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xFF8E8E93).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 60,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No access history',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your access history will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[history.length - 1 - index];
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss')
                    .format(entry.localTimestamp);

                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF34C759).withOpacity(0.2),
                                  Color(0xFF34C759).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lock_open_rounded,
                              color: Color(0xFF34C759),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Access #${entry.espAccessId}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Color(0xFF8E8E93),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
