import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'history_screen.dart'; // Layar riwayat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final String ipAddress = deviceProvider.deviceIpAddress ?? 'Tidak Diketahui';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AC-Box'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.lock_open, size: 80, color: Colors.green),
                    const SizedBox(height: 20),
                    Text(
                      'IP AC-Box: $ipAddress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // 1. Autentikasi Sidik Jari
                bool isAuthenticated = await AuthService.authenticate();

                if (isAuthenticated) {
                  // 2. Jika berhasil, kirim perintah ke ESP32
                  bool success = await ApiService.unlockDoor(ipAddress);

                  // 3. Tampilkan hasil
                  if (success) {
                    if (mounted) { // Cek mounted sebelum menampilkan snackbar
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Pintu dibuka!')),
                       );
                    }
                  } else {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Gagal membuka pintu.')),
                       );
                    }
                  }
                } else {
                  // 4. Jika autentikasi gagal
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Autentikasi gagal.')),
                     );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'BUKA KUNCI',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}