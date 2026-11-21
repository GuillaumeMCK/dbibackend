import 'dart:io';

import 'package:window_manager/window_manager.dart';

/// The height of the title bar [WindowFrame] draws, in logical pixels: on
/// macOS, the native one's, so the traffic lights sit in it; on Windows, the
/// one of [WindowCaption]; on Linux none, as the window keeps its native title
/// bar.
final class const WindowMetrics({required final double barHeight}) {
  static final current = _detect();

  static WindowMetrics _detect() {
    if (Platform.isWindows) {
      return const WindowMetrics(barHeight: kWindowCaptionHeight);
    }
    if (!Platform.isMacOS) return const WindowMetrics(barHeight: 0);
    // "Version 27.0.1 (Build 26A434)"
    return switch (_firstNumber(Platform.operatingSystemVersion)) {
      // Big Sur and later.
      final major? when major >= 11 => const WindowMetrics(barHeight: 28),
      _ => const WindowMetrics(barHeight: 22),
    };
  }

  static int? _firstNumber(String text) =>
      int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '');
}
