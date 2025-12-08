// lib/screens/login_screen.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import untuk navigatorKey

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final account = Provider.of<Account>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        automaticallyImplyLeading: false, // Jangan tampilkan tombol back default
      ),
      body: SingleChildScrollView( // Bungkus seluruh body dengan SingleChildScrollView
        padding: EdgeInsets.all(16.0),
        child: Column( // Kolom utama tetap sama
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tambahkan Image.asset di sini
            Image.asset(
              'assets/logoacbox.png', // Path ke logo Anda
              width: 200, // Atur lebar sesuai kebutuhan
              height: 200, // Atur tinggi sesuai kebutuhan
              fit: BoxFit.contain, // Atur cara gambar di-render
            ),
            SizedBox(height: 32), // Beri jarak antara logo dan form
            Form(
              key: _formKey,
              child: Column(
                children: [ // Kolom untuk input dan tombol
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Silakan masukkan email';
                      }
                      // Tambahkan validasi email sederhana
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Silakan masukkan password';
                      }
                      // Tambahkan validasi password jika diperlukan
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  if (_isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _performLogin(account, context),
                      child: Text('Login'),
                    ),
                  SizedBox(height: 16),
                  // Tombol untuk registrasi (opsional, bisa dibuat di layar terpisah)
                  TextButton(
                    onPressed: () {
                      // Navigasi ke layar registrasi jika ada
                      // Navigator.pushNamed(context, '/register');
                      // Untuk sementara, kita hanya tampilkan pesan
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fitur registrasi belum tersedia. Silakan buat akun di konsol Appwrite.')),
                      );
                    },
                    child: Text('Belum punya akun? Register'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogin(Account account, BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return; // Form tidak valid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await account.createEmailPasswordSession(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Jika berhasil login
      print('Login berhasil');
      // Gunakan navigator key untuk pindah ke LoadingScreen
      if (mounted) { // Cek mounted sebelum navigasi
         navigatorKey.currentState!.pushReplacementNamed('/loading');
      }
    } catch (e) {
      print('Login gagal: $e');
      String errorMessage = 'Login gagal. Silakan coba lagi.';
      if (e is AppwriteException) {
        errorMessage = e.message ?? errorMessage;
        // Contoh penanganan error spesifik
        if (e.code == 401) {
          errorMessage = 'Email atau password salah.';
        } else if (e.code == 404) {
          errorMessage = 'Akun tidak ditemukan.';
        }
      }
      if (mounted) { // Cek mounted sebelum menampilkan snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) { // Cek mounted sebelum mengubah state
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}