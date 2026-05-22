// ════════════════════════════════════════
// lib/core/constants/app_radius.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';

class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xlarge = 24;
  static const double pill = 100;
  
  static BorderRadius get smallBR => BorderRadius.circular(small);
  static BorderRadius get mediumBR => BorderRadius.circular(medium);
  static BorderRadius get largeBR => BorderRadius.circular(large);
  static BorderRadius get pillBR => BorderRadius.circular(pill);
}
