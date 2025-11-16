// lib/services/auth_service.dart

import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    bool authenticated = false;
    try {
      // Cek apakah perangkat bisa digunakan untuk autentikasi biometrik
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      // Cek apakah perangkat mendukung biometrik secara umum (tidak hanya sidik jari)
      bool isDeviceSupported = await _auth.isDeviceSupported();

      print("Can check biometrics: $canCheckBiometrics"); // Log untuk debugging
      print("Is device supported: $isDeviceSupported"); // Log untuk debugging

      if (canCheckBiometrics && isDeviceSupported) {
        authenticated = await _auth.authenticate(
          options: const AuthenticationOptions(
            biometricOnly: true, // Gunakan hanya sidik jari
            useErrorDialogs: true, // Biarkan library menampilkan dialog error jika bisa
            stickyAuth: false,
          ),
          localizedReason: 'Silakan verifikasi sidik jari Anda untuk membuka kunci.',
        );
        print("Authentication result: $authenticated"); // Log hasil
      } else {
         // Tidak ada sensor biometrik atau tidak didukung
         print('Autentikasi biometrik tidak tersedia atau tidak didukung.');
         // Di sinilah Anda mungkin ingin menampilkan pesan ke pengguna
         // contoh: showDialog untuk memberi tahu bahwa sidik jari tidak tersedia
      }
    } catch (e) {
      print('Error autentikasi (AuthService): $e'); // Log error
      // Bisa jadi error karena izin, tidak ada sidik jari terdaftar, dll.
      // Di sinilah Anda mungkin ingin menampilkan pesan ke pengguna
      // contoh: showDialog untuk memberi tahu bahwa autentikasi gagal karena alasan teknis
    }
    return authenticated;
  }
}