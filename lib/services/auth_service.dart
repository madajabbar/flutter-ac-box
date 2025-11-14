import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    bool authenticated = false;
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        authenticated = await _auth.authenticate(
          options: const AuthenticationOptions(
            biometricOnly: true, // Gunakan hanya sidik jari
            useErrorDialogs: true,
            stickyAuth: false,
          ),
          localizedReason: 'Silakan verifikasi sidik jari Anda untuk membuka kunci.',
        );
      } else {
         // Tidak ada sensor biometrik atau tidak didukung
         // Anda bisa menawarkan alternatif seperti PIN di sini
         print('Autentikasi biometrik tidak tersedia atau tidak didukung.');
      }
    } catch (e) {
      print('Error autentikasi: $e');
      // Mungkin tampilkan pesan kesalahan ke pengguna
    }
    return authenticated;
  }
}