import 'package:flutter/material.dart';

enum WindowSizeClass { compact, medium, expanded }

class Breakpoints {
  Breakpoints._();

  static const double compactMax = 599.0;
  static const double mediumMax = 1023.0;

  static WindowSizeClass fromWidth(double width) {
    if (width < 600) {
      return WindowSizeClass.compact;
    } else if (width < 1024) {
      return WindowSizeClass.medium;
    } else {
      return WindowSizeClass.expanded;
    }
  }
}

extension ResponsiveContext on BuildContext {
  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  double get height => size.height;

  WindowSizeClass get windowSizeClass => Breakpoints.fromWidth(width);

  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
}
