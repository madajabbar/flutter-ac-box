// lib/screens/loading_screen.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import untuk navigatorKey
import '../providers/device_provider.dart';
import 'home_screen.dart'; // Layar tujuan setelah IP dipilih

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  void initState() {
    super.initState();
    // Mulai pencarian otomatis saat screen dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.discoverDeviceByHostname();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    // Ambil instance Account untuk logout
    final account = Provider.of<Account>(context, listen: false);

    print("LoadingScreen build() dipanggil"); // Tambahkan log ini untuk debugging

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih AC-Box'),
        actions: [
          // Tambahkan tombol logout
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await account.deleteSession(sessionId: 'current'); // Logout sesi saat ini
                print('Logout berhasil');
                // Gunakan navigator key untuk kembali ke LoginScreen
                if (mounted) { // Cek mounted sebelum navigasi
                   navigatorKey.currentState!.pushReplacementNamed('/login');
                }
              } catch (e) {
                print('Logout gagal: $e');
                if (mounted) { // Cek mounted sebelum menampilkan snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout gagal: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: deviceProvider.isLoading ? null : () {
                // Reset state dan mulai pencarian lagi
                deviceProvider.reset();
                deviceProvider.discoverDeviceByHostname();
              },
              child: deviceProvider.isLoading ? const Text('Mencari...') : const Text('Cari Ulang'),
            ),
            const SizedBox(height: 20),
            if (deviceProvider.isLoading)
              const CircularProgressIndicator()
            else if (deviceProvider.foundDevices.isEmpty)
              const Center(child: Text('Tidak ada perangkat yang ditemukan. Silakan coba lagi.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: deviceProvider.foundDevices.length,
                  itemBuilder: (context, index) {
                    String ip = deviceProvider.foundDevices[index];
                    // Asumsikan nama perangkat adalah "AC-Box" karena kita mencari 'ac-box.local'
                    String deviceName = "AC-Box";
                    return Card(
                      child: ListTile(
                        // Gunakan nama sebagai title
                        title: Text(deviceName),
                        // Gunakan IP sebagai subtitle
                        subtitle: Text(ip),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Simpan IP yang dipilih
                          deviceProvider.selectDevice(ip);
                          // Pindah ke HomeScreen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}