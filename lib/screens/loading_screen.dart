// lib/screens/loading_screen.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../providers/device_provider.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.discoverDeviceByHostname();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final account = Provider.of<Account>(context, listen: false);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Select AC-Box',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Color(0xFF007AFF)),
            onPressed: () async {
              try {
                await account.deleteSession(sessionId: 'current');
                print('Logout berhasil');
                if (mounted) {
                  navigatorKey.currentState!.pushReplacementNamed('/login');
                }
              } catch (e) {
                print('Logout gagal: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout gagal: $e'),
                      backgroundColor: Color(0xFFFF3B30),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: deviceProvider.isLoading
                    ? null
                    : LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: deviceProvider.isLoading ? Color(0xFFE5E5EA) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: deviceProvider.isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: Color(0xFF007AFF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: deviceProvider.isLoading
                      ? null
                      : () {
                          deviceProvider.reset();
                          deviceProvider.discoverDeviceByHostname();
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: deviceProvider.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF8E8E93)),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Searching...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Search Again',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Content area
            if (deviceProvider.isLoading && deviceProvider.foundDevices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF007AFF)),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Searching for AC-Box...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please ensure the device is powered on',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Color(0xFFAEAEB2),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (deviceProvider.foundDevices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF3B30).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No devices found',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (deviceProvider.lastError != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            deviceProvider.lastError!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        )
                      else
                        Text(
                          'Please try searching again',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: deviceProvider.foundDevices.length,
                  itemBuilder: (context, index) {
                    String ip = deviceProvider.foundDevices[index];
                    String deviceName = "AC-Box";
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              deviceProvider.selectDevice(ip);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const HomeScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF007AFF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.router_rounded,
                                      color: Color(0xFF007AFF),
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deviceName,
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1C1C1E),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          ip,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Color(0xFF8E8E93),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFFD1D1D6),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
