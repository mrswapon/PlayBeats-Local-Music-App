import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class BrowseState extends Equatable {
  const BrowseState();

  @override
  List<Object?> get props => [];
}

class BrowseInitial extends BrowseState {}

class BrowseLoading extends BrowseState {}

class BrowseArtistsLoaded extends BrowseState {
  final List<ArtistModel> artists;
  const BrowseArtistsLoaded(this.artists);

  @override
  List<Object?> get props => [artists];
}

class BrowseAlbumsLoaded extends BrowseState {
  final List<AlbumModel> albums;
  const BrowseAlbumsLoaded(this.albums);

  @override
  List<Object?> get props => [albums];
}

class BrowseSongsLoaded extends BrowseState {
  final List<Song> songs;
  final String title;
  const BrowseSongsLoaded({required this.songs, required this.title});

  @override
  List<Object?> get props => [songs, title];
}

class BrowseError extends BrowseState {
  final String message;
  const BrowseError(this.message);

  @override
  List<Object?> get props => [message];
}
