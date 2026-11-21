import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/theme/theme.dart';
import '/i18n/i18n.g.dart';
import 'bootstrap_cubit.dart';

/// The bootstrap's progress, or why it failed.
class const BootstrapView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BootstrapCubit>().state;
    return Center(
      child: switch (state) {
        BootstrapLoading(:final task) => Text(
          _name(task),
          style: TextStyles.dim,
        ),
        BootstrapError(:final task) => Text(
          t.bootstrap.failed(task: _name(task)),
          style: const TextStyle(color: Palette.error),
        ),
        BootstrapInitial() || BootstrapLoaded() => const SizedBox.shrink(),
      },
    );
  }

  static String _name(BootstrapTask task) => switch (task) {
    .window => t.bootstrap.window,
  };
}
