import 'package:brigada_radio_streaming/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BrigadaRadioApp());
}

class BrigadaRadioApp extends StatelessWidget {
  const BrigadaRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brigada Radio Streaming',
      home: const SplashScreen(), // Start from SplashScreen
    );
  }
}