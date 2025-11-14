import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart'; // Pastikan ini adalah versi 0.3.2+2
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final MDnsClient _mdnsClient = MDnsClient();

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    try {
      await _mdnsClient.start();

      // Langkah 1: Cari PTR record untuk layanan HTTP
      await for (final PtrResourceRecord ptrRecord in _mdnsClient.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp'),
      )) {
        print('DEBUG: PTR ditemukan: ${ptrRecord.domainName}'); // Log untuk debugging

        // Langkah 2: Periksa apakah nama PTR cocok dengan 'ac-box' (case-insensitive)
        // Format nama mungkin seperti: 'ac-box._http._tcp.local.' atau 'ac-box.local._http._tcp.local.'
        if (ptrRecord.domainName.toLowerCase().contains('ac-box')) {
          print('DEBUG: Cocok! Nama PTR: ${ptrRecord.domainName}'); // Log untuk debugging

          // Langkah 3: Cari record SRV untuk mendapatkan hostname dan port dari PTR yang cocok
          await for (final SrvResourceRecord srvRecord in _mdnsClient.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptrRecord.domainName), // Gunakan nama dari PTR record
          )) {
            print('DEBUG: SRV ditemukan: ${srvRecord.target} : ${srvRecord.port}'); // Log untuk debugging

            // Langkah 4: Cari record A (IPv4) untuk hostname dari SRV record
            // NAMA KELAS YANG BENAR UNTUK VERSI multicast_dns 0.3.2+2 ADALAH AResourceRecord
            await for (final IPAddressResourceRecord aRecord in _mdnsClient.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srvRecord.target), // Gunakan hostname dari SRV record
            )) {
              print('DEBUG: A Record ditemukan: ${aRecord.address}'); // Log untuk debugging

              // Berhasil! Hentikan pencarian
              _mdnsClient.stop();

              // Simpan IP yang ditemukan ke dalam provider
              deviceProvider.setIpAddress(aRecord.address.address);

              // Pindah ke halaman utama
              if (mounted) { // Cek mounted sebelum navigasi
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
              return; // Keluar dari fungsi async untuk menghentikan semua loop
            }
          }
        }
        // Jika PTR tidak cocok, loop akan melanjutkan ke PTR berikutnya
      }
    } catch (e) {
      print('ERROR: mDNS Discovery gagal: $e'); // Log error
    } finally {
      // Timeout sebagai fallback jika tidak ditemukan dalam 15 detik
      await Future.delayed(const Duration(seconds: 15));
      // Hanya tampilkan dialog jika pencarian sudah selesai dan tidak menemukan IP
      if (mounted && deviceProvider.deviceIpAddress == null) {
        _mdnsClient.stop(); // Pastikan klien dihentikan
        _showNotFoundDialog();
      }
    }
  }

  void _showNotFoundDialog() {
    if (mounted) { // Cek mounted sebelum menampilkan dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Perangkat Tidak Ditemukan'),
            content: const Text('AC-Box tidak ditemukan di jaringan. Pastikan perangkat terhubung ke jaringan yang sama.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  // Restart proses pencarian
                  setState(() {
                    _startDiscovery();
                  });
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _mdnsClient.stop(); // Pastikan klien mDNS dihentikan saat widget dibuang
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Mencari AC-Box di jaringan...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}