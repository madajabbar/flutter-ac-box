// lib/screens/login_screen.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> _savedEmails = [];
  bool _isLoadingEmails = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = prefs.getStringList('saved_emails') ?? [];
      setState(() {
        _savedEmails = emails;
        _isLoadingEmails = false;
      });
    } catch (e) {
      print('Error loading saved emails: $e');
      setState(() {
        _isLoadingEmails = false;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emails = prefs.getStringList('saved_emails') ?? [];

      // Hapus email jika sudah ada (untuk memindahkannya ke posisi pertama)
      emails.remove(email);

      // Tambahkan email di posisi pertama
      emails.insert(0, email);

      // Batasi maksimal 5 email
      if (emails.length > 5) {
        emails = emails.sublist(0, 5);
      }

      await prefs.setStringList('saved_emails', emails);

      setState(() {
        _savedEmails = emails;
      });
    } catch (e) {
      print('Error saving email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = Provider.of<Account>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Jangan tampilkan tombol back default
      ),
      body: SingleChildScrollView(
        // Bungkus seluruh body dengan SingleChildScrollView
        padding: EdgeInsets.all(16.0),
        child: Column(
          // Kolom utama tetap sama
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
                children: [
                  // Kolom untuk input dan tombol
                  if (_isLoadingEmails)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        suffixIcon: SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      enabled: false,
                    )
                  else
                    Autocomplete<String>(
                      initialValue:
                          TextEditingValue(text: _emailController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _savedEmails;
                        }
                        return _savedEmails.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _emailController.text = selection;
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        // Sinkronkan dengan _emailController
                        fieldTextEditingController.text = _emailController.text;
                        fieldTextEditingController.addListener(() {
                          _emailController.text =
                              fieldTextEditingController.text;
                        });

                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            suffixIcon: _savedEmails.isNotEmpty
                                ? Icon(Icons.arrow_drop_down)
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan email';
                            }
                            // Tambahkan validasi email sederhana
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        );
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
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  if (_isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _performLogin(account, context),
                      child: Text('Login'),
                    ),
                  SizedBox(height: 16)
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

      // Simpan email ke SharedPreferences
      await _saveEmail(_emailController.text);

      // Gunakan navigator key untuk pindah ke LoadingScreen
      if (mounted) {
        // Cek mounted sebelum navigasi
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
      if (mounted) {
        // Cek mounted sebelum menampilkan snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        // Cek mounted sebelum mengubah state
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
