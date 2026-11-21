import 'dart:io';

/// The native title bar height of the running OS, in logical pixels, so the
/// frameless window lines up with its native buttons.
final class const WindowMetrics({required final double barHeight}) {
  static final current = _detect();

  static WindowMetrics _detect() {
    if (Platform.isMacOS) {
      // "Version 27.0.1 (Build 26A434)"
      return switch (_firstNumber(Platform.operatingSystemVersion)) {
        // Big Sur and later.
        final major? when major >= 11 => const WindowMetrics(barHeight: 28),
        _ => const WindowMetrics(barHeight: 22),
      };
    }
    if (Platform.isWindows) return const WindowMetrics(barHeight: 32);
    // GNOME (libadwaita) header bars.
    return const WindowMetrics(barHeight: 47);
  }

  static int? _firstNumber(String text) =>
      int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '');
}
