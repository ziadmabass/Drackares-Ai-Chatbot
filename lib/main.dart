import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:project_ai/const.dart';
import 'package:project_ai/homeScreen.dart';

void main() {
  Gemini.init(apiKey: GENINI_API_KEY);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Homescreen(),
    );
  }
}
