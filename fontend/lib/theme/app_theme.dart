import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single "mood" the app can wear — background gradient + accent
/// gradient used on buttons/highlights. The user can cycle through
/// these (see [AppMoods.next]) so the whole UI's colour combination
/// changes dynamically, screen to screen or on demand.
class AppMood {
  final String name;
  final List<Color> background;
  final List<Color> accent;
  final Color textOnAccent;

  const AppMood({
    required this.name,
    required this.background,
    required this.accent,
    this.textOnAccent = Colors.white,
  });
}

class AppMoods {
  static const List<AppMood> all = [
    AppMood(
      name: 'Midnight Emerald',
      background: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      accent: [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    AppMood(
      name: 'Royal Violet',
      background: [Color(0xFF41295a), Color(0xFF2F0743)],
      accent: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ),
    AppMood(
      name: 'Sunset Ember',
      background: [Color(0xFF232526), Color(0xFF414345)],
      accent: [Color(0xFFF7971E), Color(0xFFFFD200)],
      textOnAccent: Colors.black87,
    ),
    AppMood(
      name: 'Ocean Steel',
      background: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      accent: [Color(0xFF00C6FB), Color(0xFF005BEA)],
    ),
    AppMood(
      name: 'Rose Gold',
      background: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      accent: [Color(0xFFEE9CA7), Color(0xFFFFDDE1)],
      textOnAccent: Colors.black87,
    ),
    AppMood(
      name: 'Forest Gold',
      background: [Color(0xFF134E5E), Color(0xFF71B280)],
      accent: [Color(0xFFF2994A), Color(0xFFF2C94C)],
      textOnAccent: Colors.black87,
    ),
  ];

  static AppMood next(AppMood current) {
    final idx = all.indexOf(current);
    return all[(idx + 1) % all.length];
  }
}

class AppTheme {
  static ThemeData themeFor(AppMood mood) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: mood.accent.first,
        secondary: mood.accent.last,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
