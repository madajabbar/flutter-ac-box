// lib/providers/device_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/access_log_entry.dart';

class DeviceProvider with ChangeNotifier {
  String? _deviceIpAddress;
  String? get deviceIpAddress => _deviceIpAddress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> _foundDevices = [];
  List<String> get foundDevices => _foundDevices;

  // Tambahkan variabel untuk riwayat lokal
  List<AccessLogEntry> _localHistory = [];
  List<AccessLogEntry> get localHistory => _localHistory;

  // Tidak perlu Timer jika kita hanya ingin mencari satu kali
  void setIpAddress(String ip) {
    _deviceIpAddress = ip;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void reset() {
    _deviceIpAddress = null;
    _foundDevices.clear();
    _isLoading = true;
    // Kosongkan riwayat lokal saat reset
    _localHistory.clear();
    notifyListeners();
  }

  // Fungsi untuk menambahkan entri baru ke riwayat lokal
  void addAccessLogLocally(int espAccessId) {
    final newEntry = AccessLogEntry.fromData(DateTime.now(), espAccessId);
    _localHistory.add(newEntry);
    // Opsional: Batasi jumlah entri lokal
    if (_localHistory.length > 50) {
        _localHistory.removeAt(0); // Hapus entri paling lama jika melebihi batas
    }
    notifyListeners(); // Update UI
  }

  // Fungsi untuk menghapus semua entri lokal
  void clearLocalHistory() {
    _localHistory.clear();
    notifyListeners(); // Update UI
  }

  // Fungsi untuk mencari perangkat menggunakan DNS lookup untuk ac-box.local
  Future<void> discoverDeviceByHostname() async {
    print("Memulai pencarian dengan hostname ac-box.local..."); // Log awal
    setLoading(true);
    _foundDevices.clear();

    try {
      // Coba resolve hostname "ac-box.local"
      final addresses = await InternetAddress.lookup('ac-box.local');
      print("Jumlah alamat ditemukan: ${addresses.length}");

      for (final address in addresses) {
        if (address.type == InternetAddressType.IPv4) {
          print("Alamat IPv4 ditemukan: ${address.address}");
          _foundDevices.add(address.address);
        }
      }

      if (_foundDevices.isEmpty) {
        print("Tidak ada alamat IPv4 ditemukan untuk ac-box.local");
      }

    } catch (e) {
      print('Error dalam pencarian DNS: $e');
    } finally {
      setLoading(false);
      notifyListeners(); // Update UI
    }
  }

  // Fungsi untuk memilih perangkat dari daftar yang ditemukan
  void selectDevice(String ip) {
    _deviceIpAddress = ip;
    notifyListeners();
  }
}