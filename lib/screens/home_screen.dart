// lib/screens/home_screen.dart

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import '../main.dart';
import '../providers/device_provider.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _hardcodedKey = 'A1B2C3D4E5F67890GHIJKLMNOPQRSTUV';
  static const String _hardcodedIV = 'WXYZ1234567890AB';
  bool _isUnlocking = false;
  bool _isDisconnecting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _sendEncryptedUnlockCommand(String ipAddress) async {
    setState(() {
      _isUnlocking = true;
    });

    try {
      final key = enc.Key.fromUtf8(_hardcodedKey);
      final iv = enc.IV.fromUtf8(_hardcodedIV);
      final encrypter =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: "PKCS7"));

      final nonce = DateTime.now().millisecondsSinceEpoch;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final data = {
        'command': 'buka',
        'timestamp': timestamp,
        'nonce': nonce,
      };
      final jsonString = jsonEncode(data);

      print('Data Asli: $jsonString');

      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      final encryptedBase64 = encrypted.base64;

      print('Kode Enkripsi (Base64): $encryptedBase64');

      final encodedCode = Uri.encodeComponent(encryptedBase64);
      print('Kode Enkripsi (URL Encoded): $encodedCode');

      final response = await http
          .get(Uri.parse('http://$ipAddress:80/buka?code=$encodedCode'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Perintah terenkripsi dikirim dan diterima oleh ESP32.');
        final idString = response.body.trim();
        final id = int.tryParse(idString);
        if (id != null) {
          final deviceProvider =
              Provider.of<DeviceProvider>(context, listen: false);
          deviceProvider.addAccessLogLocally(id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Door unlocked successfully!'),
                  ],
                ),
                backgroundColor: Color(0xFF34C759),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else {
          print('Gagal menguraikan ID dari respons ESP32: ${response.body}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to unlock door (invalid response).'),
                backgroundColor: Color(0xFFFF3B30),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        print('Gagal mengirim perintah terenkripsi: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send command to ESP32.'),
              backgroundColor: Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('Error membuat/mengirim perintah terenkripsi: $e');

      // Check if it's a connection error
      bool isConnectionError = e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException');

      if (mounted) {
        if (isConnectionError) {
          // Show dialog with rescan option
          _showConnectionErrorDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Encryption error: $e'),
              backgroundColor: Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
      }
    }
  }

  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFFF3B30)),
            SizedBox(width: 12),
            Text(
              'Connection Failed',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Cannot connect to AC-Box. The device may be offline or the IP address has changed.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Color(0xFF8E8E93),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performRescan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Rescan',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performRescan() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final success = await deviceProvider.rescanDevice();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('AC-Box found at ${deviceProvider.deviceIpAddress}'),
              ],
            ),
            backgroundColor: Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deviceProvider.lastError ?? 'Failed to find AC-Box'),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFFF3B30), size: 28),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              height: 1.5,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFFF3B30).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final account = Provider.of<Account>(context, listen: false);
        await account.deleteSession(sessionId: 'current');

        if (mounted) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        print('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _disconnectWiFi() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final String ipAddress = deviceProvider.deviceIpAddress ?? '';

    if (ipAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AC-Box IP address not found.'),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Color(0xFFFF3B30), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Disconnect WiFi?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will disconnect the ESP32 from WiFi. You will need to reconfigure the WiFi settings to reconnect.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              height: 1.5,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFFF3B30).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Disconnect',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDisconnecting = true;
    });

    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:80/disconnect_wifi'))
          .timeout(Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('WiFi disconnected successfully!'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect: ${response.statusCode}'),
              backgroundColor: Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('Error disconnecting WiFi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
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
          _isDisconnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final String ipAddress = deviceProvider.deviceIpAddress ?? 'Unknown';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'AC-Box',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: _isDisconnecting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF3B30)),
                    ),
                  )
                : Icon(Icons.wifi_off_rounded, color: Color(0xFFFF3B30)),
            tooltip: 'Disconnect WiFi',
            onPressed: _isDisconnecting ? null : _disconnectWiFi,
          ),
          Consumer<DeviceProvider>(
            builder: (context, provider, _) => IconButton(
              icon: provider.isScanning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: Color(0xFF007AFF)),
              onPressed: provider.isScanning ? null : _performRescan,
              tooltip: 'Rescan AC-Box',
            ),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: Color(0xFF007AFF)),
            tooltip: 'Access History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Color(0xFFFF3B30)),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Spacer(),
              // Device Info Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF34C759).withOpacity(0.2),
                            Color(0xFF34C759).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        size: 64,
                        color: Color(0xFF34C759),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ipAddress != 'Unknown'
                                ? Color(0xFF34C759)
                                : Color(0xFFFF3B30),
                            boxShadow: [
                              BoxShadow(
                                color: (ipAddress != 'Unknown'
                                        ? Color(0xFF34C759)
                                        : Color(0xFFFF3B30))
                                    .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          ipAddress != 'Unknown' ? 'Connected' : 'Disconnected',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ipAddress,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Unlock Button
              ScaleTransition(
                scale: _isUnlocking
                    ? _pulseAnimation
                    : AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isUnlocking
                          ? [Color(0xFF8E8E93), Color(0xFF636366)]
                          : [Color(0xFF34C759), Color(0xFF248A3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_isUnlocking
                                ? Color(0xFF8E8E93)
                                : Color(0xFF34C759))
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUnlocking
                          ? null
                          : () async {
                              bool isAuthenticated =
                                  await AuthService.authenticate();

                              if (isAuthenticated) {
                                final deviceProvider =
                                    Provider.of<DeviceProvider>(context,
                                        listen: false);
                                final String ipAddress =
                                    deviceProvider.deviceIpAddress ?? '';
                                if (ipAddress.isEmpty) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'AC-Box IP address not found.'),
                                        backgroundColor: Color(0xFFFF3B30),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                await _sendEncryptedUnlockCommand(ipAddress);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Authentication failed.'),
                                      backgroundColor: Color(0xFFFF3B30),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: _isUnlocking
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'UNLOCKING...',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'UNLOCK',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
