import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/extensions/byte_size.dart';
import '/core/hooks/use_highlight.dart';
import '/core/widgets/widgets.dart';
import 'titles_bloc.dart';
import 'titles_remove_dialog.dart';

/// A queued title: its name and size. Clicking it (or Enter while focused)
/// removes it from the list, once confirmed, unless the list is [locked].
class const TitlesRow(
  final TitlesItem title, {
  super.key,
  final bool locked = false,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final (:highlighted, :detector) = useHighlight();
    final removable = !locked;
    return detector(
      onActivate: removable ? () => _remove(context) : null,
      child: Bar(
        selected: highlighted,
        child: Row(
          spacing: 12,
          children: [
            Expanded(child: Text(title.name, overflow: .ellipsis)),
            SizedBox(
              width: 80,
              child: Text(title.size.bytes, textAlign: .right),
            ),
            SizedBox(
              width: 16,
              child: Text(highlighted && removable ? 'x' : ''),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final titles = context.read<TitlesBloc>();
    if (await TitlesRemoveDialog.confirm(context, title.name)) {
      titles.add(TitlesRemoved(title.name));
    }
  }
}
