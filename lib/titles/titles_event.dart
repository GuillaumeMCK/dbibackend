part of 'titles_bloc.dart';

sealed class const TitlesEvent();

/// Files and folders were dropped: queue the titles found in [paths].
final class const TitlesAdded(final Iterable<String> paths) extends TitlesEvent;

/// Remove [name], unless it is being sent.
final class const TitlesRemoved(final String name) extends TitlesEvent;

/// Remove every title that isn't being sent.
final class const TitlesCleared() extends TitlesEvent;

/// The Switch went away: titles still being sent can't be resumed, and the
/// next session lists the titles afresh.
final class const TitlesSessionEnded() extends TitlesEvent;

/// The Switch was given [names].
final class const _TitlesListed(final Set<String> names) extends TitlesEvent;

/// Publish the ranges sent since the last progress update.
final class const _TitlesProgressed() extends TitlesEvent;

final class const _TitlesSendFailed(final String name, final String message)
    extends TitlesEvent;
