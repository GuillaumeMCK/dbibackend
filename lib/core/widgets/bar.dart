import 'package:flutter/widgets.dart';

import '/core/theme/theme.dart';

/// A full-width row, drawn as a highlighted selection bar when [selected].
class const Bar({
  super.key,
  required final Widget child,
  final bool selected = false,
  final Color color = Palette.white,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const .symmetric(horizontal: 8, vertical: 2),
    color: selected ? color : color.withAlpha(0),
    child: selected
        ? DefaultTextStyle.merge(
            style: const TextStyle(color: Palette.onBar),
            child: child,
          )
        : child,
  );
}
