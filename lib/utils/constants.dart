import 'package:flutter/material.dart';

class AppConstants {
  // Girly theme colors
  static const Color primaryPink = Color(0xFFFF6B81);
  static const Color secondaryPink = Color(0xFFFFA8B8);
  static const Color backgroundPink = Color(0xFFFFF0F5);
  static const Color lightPink = Color(0xFFFFDDE1);
  static const Color textDark = Color(0xFF4A4A4A);
  static const Color primaryGreen = Color(0xFF4CAF50);

  static const double defaultPadding = 16.0;

  // Task categories
  static const String choreCategory = 'Chore';
  static const String studyCategory = 'Study';
  static const String prayerCategory = 'Prayer';

  // Avatars
  static const List<String> avatars = [
    'build/assets/avatars/unicorn.png',
    'build/assets/avatars/cat.png',
    'build/assets/avatars/dog.png',
    'build/assets/avatars/bird.png',
    'build/assets/avatars/rabbit.png',
  ];

  // Chore icons (name to IconData mapping)
  static const Map<String, IconData> choreIcons = {
    'broom': Icons.cleaning_services,
    'toothbrush': Icons.brush,
    'exercise': Icons.fitness_center,
    'kind_words': Icons.chat_bubble,
    'heart': Icons.favorite,
  };

  // Available chore icon names
  static const List<String> choreIconNames = [
    'broom',
    'toothbrush',
    'exercise',
    'kind_words',
    'heart',
  ];

  // Gradient for progress bar
  static const LinearGradient progressGradient = LinearGradient(
    colors: [primaryPink, secondaryPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Text styles (no custom font)
  static const TextStyle subheadingTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryPink,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: textDark,
  );
}
