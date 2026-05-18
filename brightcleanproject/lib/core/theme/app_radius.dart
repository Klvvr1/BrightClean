import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // Core Radius Tokens
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  // Common BorderRadii
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius input = BorderRadius.circular(md);
  static final BorderRadius bottomSheet = const BorderRadius.vertical(top: Radius.circular(xl));
  static final BorderRadius dialog = BorderRadius.circular(lg);
}
