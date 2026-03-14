import 'package:equatable/equatable.dart';

abstract class AudiosEvent extends Equatable {
  const AudiosEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllAudios extends AudiosEvent {}

class RefreshAudios extends AudiosEvent {}

class SearchAudios extends AudiosEvent {
  final String query;
  const SearchAudios(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends AudiosEvent {}
