import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart' hide Window;

/// Native setup of the frameless main window.
abstract final class WindowSetup {
  static const minimumSize = Size(560, 420);

  /// Runs before the first frame: hides the native title bar, which
  /// [WindowFrame] draws instead around the native window buttons, and opens
  /// the window at its minimum size, centered.
  static void setUp() {
    final size = minimumSize.toNative();
    WindowManager.instance.getCurrent()
      ?..titleBarStyle = .hidden
      ..isWindowControlButtonsVisible = true
      ..minimumSize = size
      ..setSize(size, false)
      ..center();
  }
}
