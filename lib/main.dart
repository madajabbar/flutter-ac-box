import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'screens/loading_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DeviceProvider(),
      child: MaterialApp(
        title: 'AC-Box App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LoadingScreen(), // Mulai dengan layar loading
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}