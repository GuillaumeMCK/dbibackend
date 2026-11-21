import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Whether the widget built with `detector` is highlighted, being hovered or
/// focused from the keyboard.
///
/// `detector` gives that widget its own focus node, so Tab and the arrow keys
/// reach it, and runs `onActivate` on a click, Enter or Space; without
/// `onActivate` it only highlights.
({
  bool highlighted,
  Widget Function({
    required Widget child,
    VoidCallback? onActivate,
    bool autofocus,
  })
  detector,
})
useHighlight() {
  final focusNode = useFocusNode();
  final hovered = useState(false);
  final focused = useState(false);
  return (
    highlighted: hovered.value || focused.value,
    detector: ({required child, onActivate, autofocus = false}) =>
        FocusableActionDetector(
          focusNode: focusNode,
          autofocus: autofocus,
          mouseCursor: onActivate == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          onShowHoverHighlight: (value) => hovered.value = value,
          // Only while using the keyboard: a click doesn't leave a highlight.
          onShowFocusHighlight: (value) => focused.value = value,
          actions: {
            if (onActivate != null)
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => onActivate(),
              ),
          },
          child: GestureDetector(onTap: onActivate, child: child),
        ),
  );
}
