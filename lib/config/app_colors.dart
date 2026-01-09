import 'package:flutter/material.dart';

/// App color palette based on helpdesk web theme
class AppColors {
  AppColors._();

  // Primary Colors (from helpdesk web)
  static const Color background = Color(0xFFF5F5F5); // Putih/Cream
  static const Color primary = Color(0xFF17263A); // Biru Gelap
  static const Color lightGray = Color(0xFFE0E0E0); // Abu-abu Muda

  // Supporting Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF17263A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Ticket Status Colors
  static const Color statusNew = Color(0xFF2196F3); // Blue
  static const Color statusInProgress = Color(0xFFFF9800); // Orange
  static const Color statusSolved = Color(0xFF4CAF50); // Green
  static const Color statusClosed = Color(0xFF9E9E9E); // Gray
}
