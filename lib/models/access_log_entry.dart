// lib/models/access_log_entry.dart

class AccessLogEntry {
  final DateTime localTimestamp; // Waktu lokal saat akses dicatat di Flutter
  final int espAccessId;         // ID akses yang dikirim oleh ESP32

  AccessLogEntry({required this.localTimestamp, required this.espAccessId});

  // Fungsi untuk membuat instance dari waktu lokal dan ID ESP
  factory AccessLogEntry.fromData(DateTime timestamp, int id) {
    return AccessLogEntry(localTimestamp: timestamp, espAccessId: id);
  }

  // Fungsi untuk membuat instance dari Map (jika perlu menyimpan ke JSON lokal, misalnya SharedPreferences)
  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    return AccessLogEntry(
      localTimestamp: DateTime.fromMillisecondsSinceEpoch(json['local_timestamp'] as int),
      espAccessId: json['esp_access_id'] as int,
    );
  }

  // Fungsi untuk mengubah ke Map (jika perlu menyimpan ke JSON lokal)
  Map<String, dynamic> toJson() {
    return {
      'local_timestamp': localTimestamp.millisecondsSinceEpoch,
      'esp_access_id': espAccessId,
    };
  }
}