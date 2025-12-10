// lib/providers/device_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/access_log_entry.dart';

class DeviceProvider with ChangeNotifier {
  String? _deviceIpAddress;
  String? get deviceIpAddress => _deviceIpAddress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<String> _foundDevices = [];
  List<String> get foundDevices => _foundDevices;

  String? _lastError;
  String? get lastError => _lastError;

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
    _isScanning = true;
    _foundDevices.clear();
    _lastError = null;
    notifyListeners();

    try {
      // Coba resolve hostname "ac-box.local" dengan timeout
      final addresses = await InternetAddress.lookup('ac-box.local')
          .timeout(Duration(seconds: 10));
      print("Jumlah alamat ditemukan: ${addresses.length}");

      for (final address in addresses) {
        if (address.type == InternetAddressType.IPv4) {
          print("Alamat IPv4 ditemukan: ${address.address}");
          _foundDevices.add(address.address);
        }
      }

      if (_foundDevices.isEmpty) {
        _lastError = "No IPv4 address found for ac-box.local";
        print("Tidak ada alamat IPv4 ditemukan untuk ac-box.local");
      } else {
        // Automatically select the first device
        _deviceIpAddress = _foundDevices.first;
        print("Device IP automatically set to: $_deviceIpAddress");
      }
    } catch (e) {
      print('Error dalam pencarian DNS: $e');
      if (e.toString().contains('Failed host lookup')) {
        _lastError =
            "AC-Box not found. Please ensure the device is powered on and connected to the same network.";
      } else if (e.toString().contains('TimeoutException')) {
        _lastError = "Search timeout. Please check your network connection.";
      } else {
        _lastError = "Error: $e";
      }
    } finally {
      setLoading(false);
      _isScanning = false;
      notifyListeners(); // Update UI
    }
  }

  // Fungsi untuk rescan (dipanggil dari UI)
  Future<bool> rescanDevice() async {
    print("Rescanning for AC-Box device...");
    _isScanning = true;
    _lastError = null;
    notifyListeners();

    try {
      final addresses = await InternetAddress.lookup('ac-box.local')
          .timeout(Duration(seconds: 10));

      _foundDevices.clear();
      for (final address in addresses) {
        if (address.type == InternetAddressType.IPv4) {
          _foundDevices.add(address.address);
        }
      }

      if (_foundDevices.isNotEmpty) {
        _deviceIpAddress = _foundDevices.first;
        print("Rescan successful! Device found at: $_deviceIpAddress");
        _isScanning = false;
        notifyListeners();
        return true;
      } else {
        _lastError = "No IPv4 address found for ac-box.local";
        _isScanning = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error during rescan: $e');
      if (e.toString().contains('Failed host lookup')) {
        _lastError =
            "AC-Box not found. Please ensure the device is powered on and connected to the same network.";
      } else if (e.toString().contains('TimeoutException')) {
        _lastError = "Search timeout. Please check your network connection.";
      } else {
        _lastError = "Error: $e";
      }
      _isScanning = false;
      notifyListeners();
      return false;
    }
  }

  // Fungsi untuk memilih perangkat dari daftar yang ditemukan
  void selectDevice(String ip) {
    _deviceIpAddress = ip;
    notifyListeners();
  }
}
