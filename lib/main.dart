import 'package:flutter/material.dart';
import 'package:armada_app/pages/Splash_Screen.dart'; // Import splash screen yang sudah dibuat

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Splash Screen',
      home: SplashScreen(), // Panggil SplashScreen di sini
    );
  }
}
