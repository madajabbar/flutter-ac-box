import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/access_log_entry.dart';

class ApiService {
  static Future<bool> unlockDoor(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress/buka'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error membuka kunci: $e');
      return false;
    }
  }

  static Future<List<AccessLogEntry>> fetchHistory(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress/riwayat'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => AccessLogEntry.fromJson(json)).toList();
      } else {
        print('Gagal mengambil riwayat: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error mengambil riwayat: $e');
      return [];
    }
  }
}