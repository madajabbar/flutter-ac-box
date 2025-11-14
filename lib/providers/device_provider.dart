import 'package:flutter/foundation.dart';

class DeviceProvider with ChangeNotifier {
  String? _deviceIpAddress;
  String? get deviceIpAddress => _deviceIpAddress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void setIpAddress(String ip) {
    _deviceIpAddress = ip;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Untuk mereset status jika diperlukan (misalnya saat logout manual)
  void reset() {
    _deviceIpAddress = null;
    _isLoading = true;
    notifyListeners();
  }
}