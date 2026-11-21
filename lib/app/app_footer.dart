import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/theme/theme.dart';
import '/core/widgets/widgets.dart';
import '/i18n/i18n.g.dart';
import '/link/link_cubit.dart';
import '/titles/titles_bloc.dart';
import 'app_step.dart';

/// `LABEL ... STATUS` (dots while waiting, a spinner while sending, none once
/// done), then the reason it failed, the hint, and a retry button for a failed
/// step.
class const AppFooter({super.key}) extends StatelessWidget {
  static const _error = TextStyle(color: Palette.error);

  @override
  Widget build(BuildContext context) {
    final link = context.watch<LinkCubit>();
    final AppProgress(:step, :status, :activity, :hint, :error, :failed) = .of(
      context.watch<TitlesBloc>().state,
      link.state,
    );
    return Padding(
      padding: Insets.row,
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 2,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(child: Text(step.label, style: TextStyles.accent)),
              ?switch (activity) {
                .waiting => const Dots(),
                .sending => const Spinner(),
                null => null,
              },
              if (status != null)
                Flexible(
                  child: Text(
                    status,
                    overflow: .ellipsis,
                    style: failed ? _error : null,
                  ),
                ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    if (error != null) Text(error, style: _error),
                    Text(hint, overflow: .ellipsis, style: TextStyles.dim),
                  ],
                ),
              ),
              if (failed) Button(t.steps.retry, onPressed: link.retry),
            ],
          ),
        ],
      ),
    );
  }
}
