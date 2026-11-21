import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/extensions/byte_size.dart';
import '/core/theme/theme.dart';
import '/core/widgets/widgets.dart';
import '/i18n/i18n.g.dart';
import 'titles_row.dart';
import 'titles_bloc.dart';

/// The queued titles and how far each one was sent; a drop prompt while the
/// queue is empty.
class const TitlesView({super.key, required final bool dragging})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<TitlesBloc>().state;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _Summary(state),
        const SizedBox(height: 4),
        Expanded(
          child: switch (state) {
            TitlesState(titles: [], scanning: true) => _Prompt(
              t.titles.scanning,
            ),
            TitlesState(titles: []) => _Prompt(
              t.titles.dropHere,
              highlighted: dragging,
            ),
            TitlesState(:final titles) => ListView.builder(
              itemCount: titles.length,
              itemBuilder: (context, index) => TitlesRow(titles[index]),
            ),
          },
        ),
        if (dragging && state.titles.isNotEmpty)
          Bar(selected: true, child: Center(child: Text(t.titles.dropToAdd))),
      ],
    );
  }
}

class const _Summary(final TitlesState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: Insets.row,
    child: Row(
      spacing: 12,
      children: [
        Text(t.titles.header, style: TextStyles.accent),
        Expanded(
          child: Text(switch (state.titles) {
            [] => '',
            final titles => t.titles.summary(
              n: titles.length,
              size: state.totalSize.bytes,
            ),
          }, style: TextStyles.dim),
        ),
        if (state.titles.isNotEmpty)
          Button(
            t.titles.clear,
            onPressed: () =>
                context.read<TitlesBloc>().add(const TitlesCleared()),
          ),
      ],
    ),
  );
}

class const _Prompt(final String text, {final bool highlighted = false})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Bar(selected: highlighted, child: Text(text)),
  );
}
