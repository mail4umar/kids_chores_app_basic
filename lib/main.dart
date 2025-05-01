import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const KidsTaskTrackerApp());
}

class KidsTaskTrackerApp extends StatelessWidget {
  const KidsTaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Task Tracker',
      theme: ThemeData(
        primaryColor: AppConstants.primaryPink,
        scaffoldBackgroundColor: AppConstants.backgroundPink,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryPink,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicNeue',
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'ComicNeue',
            color: AppConstants.textDark,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryPink,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontFamily: 'ComicNeue'),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: AppConstants.lightPink,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
