/// The parts of a file sent so far, as sorted, disjoint `[start, end)` ranges.
///
/// DBI reads a title out of order (headers and footers first, then the
/// contents, sometimes twice), so progress is the bytes covered, not the
/// furthest offset.
final class const TitlesRanges([final List<(int, int)> ranges = const []]) {
  /// These ranges plus `[start, end)`.
  TitlesRanges add(int start, int end) {
    final merged = <(int, int)>[];
    var (from, to) = (start, end);
    for (final (rangeStart, rangeEnd) in ranges) {
      if (rangeEnd < from) {
        merged.add((rangeStart, rangeEnd));
      } else if (rangeStart > to) {
        merged.add((from, to));
        (from, to) = (rangeStart, rangeEnd);
      } else {
        (from, to) = (
          rangeStart < from ? rangeStart : from,
          rangeEnd > to ? rangeEnd : to,
        );
      }
    }
    return TitlesRanges([...merged, (from, to)]);
  }

  int get bytes =>
      ranges.fold(0, (total, range) => total + range.$2 - range.$1);
}

/// How far a queued title was sent to the Switch.
sealed class const TitlesStatus();

final class const TitlesQueued() extends TitlesStatus;

final class const TitlesSending(final TitlesRanges sent) extends TitlesStatus;

final class const TitlesCompleted() extends TitlesStatus;

/// Sending stopped because the Switch went away.
final class const TitlesInterrupted() extends TitlesStatus;

/// Reading the file failed with [message].
final class const TitlesFailed(final String message) extends TitlesStatus;

/// A title offered to the Switch under its file [name].
final class const TitlesItem({
  required final String name,
  required final String path,
  required final int size,
  final TitlesStatus status = const TitlesQueued(),
}) {
  TitlesItem withStatus(TitlesStatus status) =>
      TitlesItem(name: name, path: path, size: size, status: status);
}

final class const TitlesState({
  final List<TitlesItem> titles = const [],
  final bool scanning = false,
  final Set<String>? listed,
}) {
  TitlesState copyWith({
    List<TitlesItem>? titles,
    bool? scanning,
    Set<String>? listed,
  }) => TitlesState(
    titles: titles ?? this.titles,
    scanning: scanning ?? this.scanning,
    listed: listed ?? this.listed,
  );

  TitlesItem? operator [](String name) =>
      titles.where((title) => title.name == name).firstOrNull;

  int get totalSize => titles.fold(0, (total, title) => total + title.size);

  int get completed => titles.where((t) => t.status is TitlesCompleted).length;

  /// The Switch listed the titles, and the queue changed since: DBI only asks
  /// for the list when its menu opens, so it shows an outdated one.
  bool get outdated => switch (listed) {
    null => false,
    final listed =>
      listed.length != titles.length ||
          titles.any((title) => !listed.contains(title.name)),
  };
}
