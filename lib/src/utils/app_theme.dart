// Тема приложения - цвета, стили, скругления

import 'package:flutter/material.dart';

class AppTheme {
  // Основные цвета (GooDoo брендбук: зелёный #589D46, серый #546670)
  static const primaryColor = Color(0xFF589D46);
  static const accentColor = Color(0xFF546670);
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFF9800);
  static const dangerColor = Color(0xFFF44336);
  static const backgroundColor = Color(0xFFF5F5F5);

  // Цвета статусов заявок
  static const pendingColor = Color(0xFF9E9E9E);
  static const inProgressColor = Color(0xFF589D46);
  static const deliveredColor = Color(0xFFFF9800);
  static const paidColor = Color(0xFF4CAF50);
  static const cancelledColor = Color(0xFFF44336);

  // Цвета маркеров на карте
  static const markerPending = Color(0xFFF44336);
  static const markerCurrent = Color(0xFF589D46);
  static const markerDone = Color(0xFF4CAF50);

  // Айфоновские скругления
  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;
  static const radiusXLarge = 20.0;

  static final borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final borderRadiusXLarge = BorderRadius.circular(radiusXLarge);

  // Тема Material
  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadiusMedium,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
