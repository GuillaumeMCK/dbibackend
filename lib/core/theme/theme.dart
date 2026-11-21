import 'package:flutter/widgets.dart';

/// The text-mode palette DBI uses on the Switch: white on deep blue.
abstract final class Palette {
  static const background = Color(0xFF000084);
  static const white = Color(0xFFF4F6FF);
  static const black = Color(0xFF000000);
  static const dim = Color(0xFF8C93D9);
  static const ok = Color(0xFF5CFFA1);
  static const error = Color(0xFFFF6B6B);
  static const transparent = Color(0x00000000);

  /// Text drawn on a highlighted bar.
  static const onBar = background;
}

abstract final class TextStyles {
  /// The system's monospace fonts, in order of preference.
  static const _fonts = [
    'Cascadia Mono', // Windows 11
    'Consolas', // Windows
    'DejaVu Sans Mono', // Linux
    'Liberation Mono',
    'monospace',
  ];

  static const body = TextStyle(
    fontFamily: 'Menlo', // macOS
    fontFamilyFallback: _fonts,
    fontSize: 13,
    height: 1.4,
    // Centers glyphs in their line, so rows read evenly in highlight bars.
    leadingDistribution: .even,
    fontWeight: FontWeight.w500,
    color: Palette.white,
  );

  static final dim = body.copyWith(color: Palette.dim);

  static final accent = body.copyWith(fontWeight: FontWeight.w700);

  static final title = accent.copyWith(letterSpacing: 2);
}

/// Paddings shared by the screens.
abstract final class Insets {
  static const row = EdgeInsets.symmetric(horizontal: 8);
}
