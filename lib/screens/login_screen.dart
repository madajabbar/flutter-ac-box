// lib/screens/login_screen.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Import untuk navigatorKey

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<String> _savedEmails = [];
  bool _isLoadingEmails = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
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
      backgroundColor: Color(0xFFF5F5F7),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F5F7),
              Color(0xFFE8EAF6),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logoacbox.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Welcome text
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 48),

                    // Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            if (_isLoadingEmails)
                              _buildModernTextField(
                                controller: TextEditingController(),
                                label: 'Email',
                                enabled: false,
                                suffixIcon: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF007AFF)),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Autocomplete<String>(
                                initialValue: TextEditingValue(
                                    text: _emailController.text),
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return _savedEmails;
                                  }
                                  return _savedEmails.where((String option) {
                                    return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase());
                                  });
                                },
                                onSelected: (String selection) {
                                  _emailController.text = selection;
                                },
                                fieldViewBuilder: (BuildContext context,
                                    TextEditingController
                                        fieldTextEditingController,
                                    FocusNode fieldFocusNode,
                                    VoidCallback onFieldSubmitted) {
                                  fieldTextEditingController.text =
                                      _emailController.text;
                                  fieldTextEditingController.addListener(() {
                                    _emailController.text =
                                        fieldTextEditingController.text;
                                  });

                                  return _buildModernTextField(
                                    controller: fieldTextEditingController,
                                    focusNode: fieldFocusNode,
                                    label: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    suffixIcon: _savedEmails.isNotEmpty
                                        ? Icon(Icons.arrow_drop_down,
                                            color: Color(0xFF8E8E93))
                                        : null,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Silakan masukkan email';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            SizedBox(height: 20),

                            // Password Field
                            _buildModernTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Silakan masukkan password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 32),

                            // Login Button
                            if (_isLoading)
                              Container(
                                height: 56,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF007AFF)),
                                ),
                              )
                            else
                              _buildModernButton(
                                onPressed: () =>
                                    _performLogin(account, context),
                                label: 'Sign In',
                              ),
                            SizedBox(height: 16),

                            // Forgot Password Link
                            TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(account),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: Color(0xFF1C1C1E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF3B30), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF3B30), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: Color(0xFFFF3B30),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog(Account account) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded,
                      color: Color(0xFF007AFF), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Color(0xFF1C1C1E),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFFE5E5EA), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFF007AFF), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFFFF3B30), width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFFFF3B30), width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        errorStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLoading ? Color(0xFFD1D1D6) : Color(0xFF8E8E93),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            // Using Appwrite console for password reset
                            // User will receive email with link to Appwrite's built-in reset page
                            await account.createRecovery(
                              email: emailController.text,
                              url: 'https://sgp.cloud.appwrite.io/console',
                            );

                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Password reset email sent! Check your inbox.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF34C759),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Password recovery error: $e');

                            setDialogState(() {
                              isLoading = false;
                            });

                            String errorMessage = 'Failed to send reset email.';
                            if (e is AppwriteException) {
                              if (e.code == 404) {
                                errorMessage = 'Email not found in our system.';
                              } else if (e.message != null) {
                                errorMessage = e.message!;
                              }
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Color(0xFFFF3B30),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: isLoading
                        ? Color(0xFFE5E5EA)
                        : Color(0xFF007AFF).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF8E8E93)),
                            ),
                          )
                        : Text(
                            'Send Reset Email',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<void> _performLogin(Account account, BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await account.createEmailPasswordSession(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print('Login berhasil');

      // Simpan email ke SharedPreferences
      await _saveEmail(_emailController.text);

      // Gunakan navigator key untuk pindah ke LoadingScreen
      if (mounted) {
        navigatorKey.currentState!.pushReplacementNamed('/loading');
      }
    } catch (e) {
      print('Login gagal: $e');
      String errorMessage = 'Login gagal. Silakan coba lagi.';
      if (e is AppwriteException) {
        errorMessage = e.message ?? errorMessage;
        if (e.code == 401) {
          errorMessage = 'Email atau password salah.';
        } else if (e.code == 404) {
          errorMessage = 'Akun tidak ditemukan.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
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
    _animationController.dispose();
    super.dispose();
  }
}
