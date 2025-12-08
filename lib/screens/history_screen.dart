// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl
import 'package:provider/provider.dart';
import '../models/access_log_entry.dart';
import '../providers/device_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Riwayat lokal diambil dari DeviceProvider
  // Tidak perlu variabel _history dan _isLoading lagi karena langsung dari provider

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final List<AccessLogEntry> history = deviceProvider.localHistory; // Ambil dari provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Akses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              // Konfirmasi penghapusan
              final confirmed = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Hapus semua riwayat lokal dan di perangkat ESP32?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                // Hapus riwayat lokal
                deviceProvider.clearLocalHistory();

                // Hapus riwayat di ESP32
                final ipAddress = deviceProvider.deviceIpAddress ?? '';
                if (ipAddress.isNotEmpty) {
                  final success = await ApiService.clearHistoryOnESP(ipAddress);
                  if (success) {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Riwayat di ESP32 dan lokal telah dihapus.')),
                       );
                    }
                  } else {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Gagal menghapus riwayat di ESP32.')),
                       );
                    }
                    // Jika gagal menghapus di ESP32, mungkin ingin mempertimbangkan untuk menyimpan ulang riwayat lokal
                  }
                }
              }
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('Belum ada riwayat akses.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[history.length - 1 - index]; // Tampilkan dari yang terbaru ke terlama
                // Gunakan waktu lokal dari Flutter
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(entry.localTimestamp);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_open, color: Colors.green),
                    title: Text('Akses ke-${entry.espAccessId}'),
                    subtitle: Text(formattedDate),
                  ),
                );
              },
            ),
    );
  }
}