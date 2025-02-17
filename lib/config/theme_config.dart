import 'package:flutter/material.dart';

class FlowTheme {
  final String id;
  final String name;
  final String collection;
  final ThemeData themeData;
  final bool isPro;
  final Color primaryColor;
  final Color accentColor;
  final Gradient backgroundGradient;
  final Color cardColor;
  final Color textColor;
  final Color navBarColor;
  final IconThemeData iconTheme;

  const FlowTheme({
    required this.id,
    required this.name,
    required this.collection,
    required this.themeData,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundGradient,
    required this.cardColor,
    required this.textColor,
    required this.navBarColor,
    required this.iconTheme,
    this.isPro = true,
  });
}

class ThemeConfig {
  // Nature Collection
  static final forestTheme = FlowTheme(
    id: 'forest',
    name: 'Forest',
    collection: 'Nature',
    primaryColor: const Color(0xFF2D2520),
    accentColor: const Color(0xFFE0C1A3),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2D2520),
        Color(0xFF241E1A),
        Color(0xFF1A1614),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF3A2E27),
    navBarColor: const Color(0xFF3A2E27),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFE0C1A3),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF2D2520),
      scaffoldBackgroundColor: const Color(0xFF2D2520),
    ),
  );

  static final oceanTheme = FlowTheme(
    id: 'ocean',
    name: 'Ocean',
    collection: 'Nature',
    primaryColor: const Color(0xFF1B3B4B),
    accentColor: const Color(0xFF64B6AC),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E4154),
        Color(0xFF15303D),
        Color(0xFF102834),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF234B5F),
    navBarColor: const Color(0xFF234B5F),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFF64B6AC),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1B3B4B),
      scaffoldBackgroundColor: const Color(0xFF1B3B4B),
    ),
  );

  static final desertTheme = FlowTheme(
    id: 'desert',
    name: 'Desert',
    collection: 'Nature',
    primaryColor: const Color(0xFF443730),
    accentColor: const Color(0xFFE8B298),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4A3C34),
        Color(0xFF382E28),
        Color(0xFF2D2520),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF574639),
    navBarColor: const Color(0xFF574639),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFE8B298),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF443730),
      scaffoldBackgroundColor: const Color(0xFF443730),
    ),
  );

  // Minimal Collection
  static final monochromeTheme = FlowTheme(
    id: 'monochrome',
    name: 'Monochrome',
    collection: 'Minimal',
    primaryColor: const Color(0xFF1A1A1A),
    accentColor: const Color(0xFFE0E0E0),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1D1D1D),
        Color(0xFF141414),
        Color(0xFF0F0F0F),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF242424),
    navBarColor: const Color(0xFF242424),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFE0E0E0),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1A1A1A),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    ),
  );

  static final grayscaleTheme = FlowTheme(
    id: 'grayscale',
    name: 'Grayscale',
    collection: 'Minimal',
    primaryColor: const Color(0xFF2C2C2C),
    accentColor: const Color(0xFFBDBDBD),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2F2F2F),
        Color(0xFF242424),
        Color(0xFF1C1C1C),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF383838),
    navBarColor: const Color(0xFF383838),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFBDBDBD),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF2C2C2C),
      scaffoldBackgroundColor: const Color(0xFF2C2C2C),
    ),
  );

  static final cleanTheme = FlowTheme(
    id: 'clean',
    name: 'Clean',
    collection: 'Minimal',
    primaryColor: const Color(0xFFF5F5F5),
    accentColor: const Color(0xFF2C2C2C),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF8F8F8),
        Color(0xFFEEEEEE),
        Color(0xFFE8E8E8),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: Colors.white,
    navBarColor: Colors.white,
    textColor: Colors.black,
    iconTheme: const IconThemeData(
      color: Color(0xFF2C2C2C),
      size: 24,
    ),
    themeData: ThemeData.light().copyWith(
      primaryColor: const Color(0xFFF5F5F5),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    ),
  );

  // Mood Collection
  static final focusTheme = FlowTheme(
    id: 'focus',
    name: 'Focus',
    collection: 'Mood',
    primaryColor: const Color(0xFF1E2A3D),
    accentColor: const Color(0xFF7EB8E1),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF213143),
        Color(0xFF1A2535),
        Color(0xFF151D2A),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF2A3A4F),
    navBarColor: const Color(0xFF2A3A4F),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFF7EB8E1),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1E2A3D),
      scaffoldBackgroundColor: const Color(0xFF1E2A3D),
    ),
  );

  static final calmTheme = FlowTheme(
    id: 'calm',
    name: 'Calm',
    collection: 'Mood',
    primaryColor: const Color(0xFF2D3B36),
    accentColor: const Color(0xFF98C9A3),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF31403A),
        Color(0xFF28332E),
        Color(0xFF212A26),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF384842),
    navBarColor: const Color(0xFF384842),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFF98C9A3),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF2D3B36),
      scaffoldBackgroundColor: const Color(0xFF2D3B36),
    ),
  );

  static final energeticTheme = FlowTheme(
    id: 'energetic',
    name: 'Energetic',
    collection: 'Mood',
    primaryColor: const Color(0xFF3D2B3D),
    accentColor: const Color(0xFFFFB4A2),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF402E40),
        Color(0xFF332333),
        Color(0xFF291B29),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF4D374D),
    navBarColor: const Color(0xFF4D374D),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFFFB4A2),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF3D2B3D),
      scaffoldBackgroundColor: const Color(0xFF3D2B3D),
    ),
  );

  // Default theme (not Pro)
  static final defaultTheme = FlowTheme(
    id: 'default',
    name: 'Default',
    collection: 'Default',
    primaryColor: const Color(0xFF17171A),
    accentColor: const Color(0xFFE0C1A3),
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A1A1D),
        Color(0xFF1E1E23),
        Color(0xFF17171A),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    cardColor: const Color(0xFF1E1E23),
    navBarColor: const Color(0xFF1E1E23),
    textColor: Colors.white,
    iconTheme: const IconThemeData(
      color: Color(0xFFE0C1A3),
      size: 24,
    ),
    themeData: ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF17171A),
      scaffoldBackgroundColor: const Color(0xFF17171A),
    ),
    isPro: false,
  );

  // All themes grouped by collection
  static final Map<String, List<FlowTheme>> themesByCollection = {
    'Nature': [forestTheme, oceanTheme, desertTheme],
    'Minimal': [monochromeTheme, grayscaleTheme, cleanTheme],
    'Mood': [focusTheme, calmTheme, energeticTheme],
  };

  // All themes in a single list
  static final List<FlowTheme> allThemes = [
    defaultTheme,
    ...themesByCollection.values.expand((themes) => themes),
  ];

  // Get theme by ID
  static FlowTheme getThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => defaultTheme,
    );
  }
} 