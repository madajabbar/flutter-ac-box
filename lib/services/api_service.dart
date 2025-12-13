// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Fungsi untuk membuka kunci dan mendapatkan ID akses
  static Future<int?> unlockDoorAndGetId(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress:80/buka'));
      if (response.statusCode == 200) {
        // Respons berisi ID akses sebagai string angka
        final idString = response.body.trim();
        final id = int.tryParse(idString);
        if (id != null) {
          print('ID Akses diterima dari ESP32: $id'); // Log untuk debugging
          return id;
        } else {
          print('Gagal menguraikan ID akses dari respons: $idString');
          return null;
        }
      } else {
        print('Gagal membuka kunci: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error membuka kunci: $e');
      return null;
    }
  }

  // Fungsi untuk mengambil array ID akses dari ESP32
  static Future<List<int>> fetchHistoryIdsFromESP(String ipAddress) async {
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress:80/riwayat'));
      if (response.statusCode == 200) {
        // Respons adalah array angka: [1, 2, 3, ...]
        final List<dynamic> jsonList = json.decode(response.body);
        // Ubah setiap angka menjadi int
        return jsonList.cast<int>();
      } else {
        print('Gagal mengambil riwayat ID dari ESP32: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error mengambil riwayat ID dari ESP32: $e');
      return [];
    }
  }

  // Fungsi untuk menghapus riwayat di ESP32
  static Future<bool> clearHistoryOnESP(String ipAddress) async {
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress:80/hapus_riwayat'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error menghapus riwayat di ESP32: $e');
      return false;
    }
  }

  // Fungsi untuk menyinkronkan waktu ESP32 dengan waktu HP
  static Future<bool> syncTimeESP(String ipAddress) async {
    try {
      // Dapatkan timestamp Unix (dalam detik)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Kirim timestamp ke ESP32
      final response = await http
          .get(Uri.parse('http://$ipAddress:80/set_time?timestamp=$timestamp'));
      if (response.statusCode == 200) {
        print('Waktu berhasil disinkronkan dengan ESP32: $timestamp');
        return true;
      } else {
        print('Gagal menyinkronkan waktu: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error menyinkronkan waktu dengan ESP32: $e');
      return false;
    }
  }
}
