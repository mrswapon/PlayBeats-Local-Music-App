import 'package:equatable/equatable.dart';

abstract class SongsEvent extends Equatable {
  const SongsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllSongs extends SongsEvent {}

class RefreshSongs extends SongsEvent {}

class SearchSongs extends SongsEvent {
  final String query;
  const SearchSongs(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends SongsEvent {}
