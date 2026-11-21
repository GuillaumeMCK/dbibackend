import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/hooks/use_highlight.dart';
import 'bar.dart';

/// A `[ LABEL ]` text button that lights up as a [Bar] when hovered or
/// focused.
class const Button(
  final String label, {
  super.key,
  required final VoidCallback onPressed,
  final bool autofocus = false,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final (:highlighted, :detector) = useHighlight();
    return detector(
      onActivate: onPressed,
      autofocus: autofocus,
      child: Bar(
        selected: highlighted,
        child: Text('[ ${label.toUpperCase()} ]'),
      ),
    );
  }
}
