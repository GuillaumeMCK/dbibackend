import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '/core/logger/logger.dart';
import '/dbi/dbi_server.dart';
import 'titles_scanner.dart';
import 'titles_state.dart';

export 'titles_state.dart';

part 'titles_event.dart';

/// The titles queued for the Switch, and how far each one was sent.
///
/// Titles are offered by file name, as DBI lists them; a name already queued
/// keeps its first file. Drops are scanned one after the other, so names are
/// always checked against an up-to-date queue.
final class TitlesBloc extends Bloc<TitlesEvent, TitlesState>
    implements DbiTitleSource {
  TitlesBloc() : super(const TitlesState()) {
    on<TitlesAdded>(_onAdded, transformer: sequential());
    on<TitlesRemoved>(
      (event, emit) => _retain(
        emit,
        (title) => title.name != event.name || title.status is TitlesSending,
      ),
    );
    on<TitlesCleared>(
      (_, emit) => _retain(emit, (title) => title.status is TitlesSending),
    );
    on<TitlesSessionEnded>(_onSessionEnded);
    on<_TitlesListed>(
      (event, emit) => emit(state.copyWith(listed: event.names)),
    );
    on<_TitlesProgressed>((_, emit) => _publishProgress(emit));
    on<_TitlesSendFailed>(_onFailed);
  }

  static const _log = kReleaseMode ? null : Logger('TitlesBloc');

  /// How often progress is published while sending: sending runs on the UI
  /// isolate, so rebuilding for every segment would slow it down.
  static const _progressInterval = Duration(milliseconds: 100);

  /// Ranges sent per title, published to [state] by [_publishProgress].
  final _sent = <String, TitlesRanges>{};
  Timer? _progressTimer;

  Future<void> _onAdded(TitlesAdded event, Emitter<TitlesState> emit) async {
    emit(state.copyWith(scanning: true));
    final names = {for (final title in state.titles) title.name};
    final found = <TitlesItem>[];
    await for (final file in TitlesScanner.scan(event.paths)) {
      final name = TitlesScanner.nameOf(file);
      if (!names.add(name)) {
        _log?.warning(
          'Skipping ${file.path}: a title with this name is queued',
        );
        continue;
      }
      found.add(
        TitlesItem(name: name, path: file.path, size: await file.length()),
      );
    }
    emit(
      state.copyWith(
        titles: [...state.titles, ...found]..sort(_byName),
        scanning: false,
      ),
    );
  }

  void _onSessionEnded(TitlesSessionEnded _, Emitter<TitlesState> emit) {
    _publishProgress(emit);
    _sent.clear();
    emit(
      TitlesState(
        titles: [
          for (final title in state.titles)
            title.status is TitlesSending
                ? title.withStatus(const TitlesInterrupted())
                : title,
        ],
        scanning: state.scanning,
      ),
    );
  }

  void _onFailed(_TitlesSendFailed event, Emitter<TitlesState> emit) {
    _publishProgress(emit);
    _sent.remove(event.name);
    emit(
      state.copyWith(
        titles: [
          for (final title in state.titles)
            title.name == event.name
                ? title.withStatus(TitlesFailed(event.message))
                : title,
        ],
      ),
    );
  }

  @override
  List<String> listTitles() {
    final names = [for (final title in state.titles) title.name];
    add(_TitlesListed(names.toSet()));
    return names;
  }

  @override
  String? pathOf(String name) => state[name]?.path;

  @override
  void onSent(String name, int start, int end) {
    // DBI may read parts of an installed title again.
    if (state[name]?.status is TitlesCompleted) return;
    _sent[name] = (_sent[name] ?? const TitlesRanges()).add(start, end);
    _progressTimer ??= Timer(
      _progressInterval,
      () => add(const _TitlesProgressed()),
    );
  }

  @override
  void onFailed(String name, Object error) =>
      add(_TitlesSendFailed(name, '$error'));

  void _publishProgress(Emitter<TitlesState> emit) {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (_sent.isEmpty) return;
    emit(
      state.copyWith(
        titles: [
          for (final title in state.titles)
            switch (_sent[title.name]) {
              null => title,
              final sent when sent.bytes >= title.size => title.withStatus(
                const TitlesCompleted(),
              ),
              final sent => title.withStatus(TitlesSending(sent)),
            },
        ],
      ),
    );
    _sent.removeWhere((name, _) => state[name]?.status is TitlesCompleted);
  }

  void _retain(Emitter<TitlesState> emit, bool Function(TitlesItem) keep) {
    final titles = state.titles.where(keep).toList();
    _sent.removeWhere((name, _) => !titles.any((title) => title.name == name));
    emit(state.copyWith(titles: titles));
  }

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }

  static int _byName(TitlesItem a, TitlesItem b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
