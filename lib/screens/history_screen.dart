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
  List<AccessLogEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final String ipAddress = deviceProvider.deviceIpAddress ?? '';

    if (ipAddress.isNotEmpty) {
      final history = await ApiService.fetchHistory(ipAddress);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Tampilkan pesan error jika IP tidak ditemukan
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Alamat IP AC-Box tidak ditemukan.')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Akses'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory, // Fungsi untuk pull-to-refresh
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? const Center(child: Text('Belum ada riwayat akses.'))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      // Format timestamp ke string tanggal/waktu
                      final dateTime = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
                      final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_open, color: Colors.green),
                          title: Text('Akses ke-$index'),
                          subtitle: Text(formattedDate),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}