import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0; // inputs, botones
  static const double lg = 16.0; // cards
  static const double xl = 24.0; // diálogos

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
}
