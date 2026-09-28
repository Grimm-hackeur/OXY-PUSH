import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

const bg = Color(0xFF0E0B1A);
const card = Color(0xFF1A1530);
const line = Color(0xFF3B2F6B);
const violet = Color(0xFF7C5CFF);
const soft = Color(0xFFB9A8FF);
const muted = Color(0xFFA99BD8);
const successColor = Color(0xFF2FBF71);
const errorColor = Color(0xFFFF6B6B);
const textPrimary = Color(0xFFF1EDFF);

void main() {
  runApp(const GitPocketApp());
}

class GitPocketApp extends StatelessWidget {
  const GitPocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GitPocket',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: violet,
          surface: card,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: violet),
      ),
      home: const SplashScreen(),
    );
  }
}
