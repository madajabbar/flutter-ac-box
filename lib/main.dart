// lib/main.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';

// Ganti dengan Project ID Appwrite Anda
const String kAppwriteProjectId = '69366f1e00362425e129';
// Ganti dengan URL Appwrite Anda (misalnya http://localhost:80/v1 atau https://your-appwrite-instance.com/v1)
const String kAppwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1'; // Sesuaikan dengan URL Anda

// --- Tambahkan Global Key untuk Navigator ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// ------------------------------------------

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi Appwrite Client
    final client = Client()
        .setEndpoint(kAppwriteEndpoint) // Ganti dengan endpoint Anda
        .setProject(kAppwriteProjectId); // Ganti dengan Project ID Anda

    // Buat instance Account untuk otentikasi
    final account = Account(client);

    return MultiProvider(
      providers: [
        // Provider untuk Appwrite Account
        Provider<Account>.value(value: account),
        // Provider untuk Device (dari sebelumnya)
        ChangeNotifierProvider(create: (context) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'AC-Box App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // Gunakan key ini di MaterialApp
        navigatorKey: navigatorKey,
        // Hapus 'home' karena kita akan mengontrol navigasi secara manual
        // home: AuthWrapper(), // Hapus baris ini
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Tentukan rute awal berdasarkan status login
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (context) => AuthWrapper());
            case '/login':
              return MaterialPageRoute(builder: (context) => LoginScreen());
            case '/loading':
              return MaterialPageRoute(builder: (context) => LoadingScreen());
            default:
              return MaterialPageRoute(builder: (context) => Scaffold(body: Center(child: Text('Page not found'))));
          }
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Widget untuk mengecek status login dan menentukan halaman awal
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAuthStatus = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final account = Provider.of<Account>(context, listen: false);
    try {
      final user = await account.get(); // Coba ambil data pengguna saat ini
      if (user.$id.isNotEmpty) {
        setState(() {
          _isLoggedIn = true;
          _isCheckingAuthStatus = false;
        });
        // Jika sudah login, arahkan ke LoadingScreen
        if (mounted) {
          navigatorKey.currentState!.pushReplacementNamed('/loading');
        }
      } else {
        setState(() {
          _isCheckingAuthStatus = false;
        });
        // Jika tidak login, arahkan ke LoginScreen
        if (mounted) {
          navigatorKey.currentState!.pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      // Jika gagal (karena tidak ada sesi), anggap tidak login
      print('Status login: Tidak ada sesi aktif - $e');
      setState(() {
        _isCheckingAuthStatus = false;
      });
      // Jika tidak login, arahkan ke LoginScreen
      if (mounted) {
         navigatorKey.currentState!.pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuthStatus) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Kita tidak perlu mengembalikan widget di sini karena navigasi sudah ditangani di initState
    // Kembalikan widget kosong sementara
    return Container();
  }
}