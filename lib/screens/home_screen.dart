// lib/screens/home_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Tambahkan import untuk library enkripsi dan http
import 'package:encrypt/encrypt.dart' as enc; // Gunakan prefix 'enc' untuk encrypt
import 'package:http/http.dart' as http; // Gunakan prefix 'http' untuk http
import '../providers/device_provider.dart';
import '../services/auth_service.dart';
import 'history_screen.dart'; // Layar riwayat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hardcode SHARED_KEY dan IV
  // Pastikan panjangnya sesuai (32 byte untuk AES-256, 16 byte untuk IV)
  static const String _hardcodedKey = 'A1B2C3D4E5F67890GHIJKLMNOPQRSTUV'; // 32 karakter acak
  static const String _hardcodedIV = 'WXYZ1234567890AB'; // 16 karakter acak

  // Fungsi untuk mengirim perintah terenkripsi ke ESP32 (Menggunakan CBC)
  Future<void> _sendEncryptedUnlockCommand(String ipAddress) async {
    try {
      final key = enc.Key.fromUtf8(_hardcodedKey);
      final iv = enc.IV.fromUtf8(_hardcodedIV);
      // Ganti AES(key) menjadi AES(key, mode: enc.AESMode.cbc, padding: "PKCS7")
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: "PKCS7"));

      // Siapkan data
      final nonce = DateTime.now().millisecondsSinceEpoch;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final data = {
        'command': 'buka',
        'timestamp': timestamp,
        'nonce': nonce,
      };
      final jsonString = jsonEncode(data);

      print('Data Asli: $jsonString');

      // Enkripsi data
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      final encryptedBase64 = encrypted.base64;

      print('Kode Enkripsi (Base64): $encryptedBase64');

      // ENCODE string Base64 untuk URL
      final encodedCode = Uri.encodeComponent(encryptedBase64);
      print('Kode Enkripsi (URL Encoded): $encodedCode');

      // Kirim ke ESP32
      final response = await http.get(Uri.parse('http://$ipAddress/buka?code=$encodedCode'));

      if (response.statusCode == 200) {
        print('Perintah terenkripsi dikirim dan diterima oleh ESP32.');
        final idString = response.body.trim();
        final id = int.tryParse(idString);
        if (id != null) {
          // Simpan ke riwayat lokal di DeviceProvider
          final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
          deviceProvider.addAccessLogLocally(id);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Pintu dibuka!')),
             );
          }
        } else {
           print('Gagal menguraikan ID dari respons ESP32: ${response.body}');
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal membuka pintu (respon tidak valid).')),
              );
           }
        }
      } else {
        print('Gagal mengirim perintah terenkripsi: ${response.statusCode}');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Gagal mengirim perintah ke ESP32.')),
           );
        }
      }
    } catch (e) {
      print('Error membuat/mengirim perintah terenkripsi: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error enkripsi: $e')),
         );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (build method tetap sama, pastikan onPressed memanggil _sendEncryptedUnlockCommand)
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
                  // 2. Jika berhasil, kirim perintah terenkripsi ke ESP32
                  final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                  final String ipAddress = deviceProvider.deviceIpAddress ?? '';
                  if (ipAddress.isEmpty) {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Alamat IP AC-Box tidak ditemukan.')),
                       );
                    }
                    return; // Keluar jika IP tidak ditemukan
                  }

                  // Gunakan fungsi baru untuk mengirim perintah terenkripsi (dengan CBC)
                  await _sendEncryptedUnlockCommand(ipAddress);

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