class AccessLogEntry {
  final int timestamp; // timestamp dalam milidetik sejak epoch

  AccessLogEntry({required this.timestamp});

  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    return AccessLogEntry(
      timestamp: json['timestamp'] as int? ?? 0, // Default ke 0 jika tidak ada
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
    };
  }
}