import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/hooks/use_highlight.dart';
import 'bar.dart';

/// A `[x] Label` text checkbox that lights up as a [Bar] when hovered or
/// focused.
class const CheckBox(
  final String label, {
  super.key,
  required final bool value,
  required final ValueChanged<bool> onChanged,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final (:highlighted, :detector) = useHighlight();
    return detector(
      onActivate: () => onChanged(!value),
      child: Bar(
        selected: highlighted,
        child: Text('[${value ? 'x' : ' '}] $label'),
      ),
    );
  }
}
