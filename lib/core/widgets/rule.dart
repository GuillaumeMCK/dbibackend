import 'package:flutter/widgets.dart';

import '/core/theme/theme.dart';

class const Rule({super.key, final Color color = Palette.dim})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 8),
    child: SizedBox(height: 1, child: ColoredBox(color: color)),
  );
}
