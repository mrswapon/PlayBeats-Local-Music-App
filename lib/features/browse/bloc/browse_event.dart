import 'package:equatable/equatable.dart';

abstract class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object?> get props => [];
}

class LoadArtists extends BrowseEvent {}

class LoadAlbums extends BrowseEvent {}

class LoadArtistSongs extends BrowseEvent {
  final int artistId;
  final String artistName;
  const LoadArtistSongs({required this.artistId, required this.artistName});

  @override
  List<Object?> get props => [artistId, artistName];
}

class LoadAlbumSongs extends BrowseEvent {
  final int albumId;
  final String albumName;
  const LoadAlbumSongs({required this.albumId, required this.albumName});

  @override
  List<Object?> get props => [albumId, albumName];
}

class BackToBrowse extends BrowseEvent {}
