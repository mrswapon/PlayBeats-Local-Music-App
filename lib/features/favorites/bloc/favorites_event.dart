import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class AddToFavorites extends FavoritesEvent {
  final Song song;

  const AddToFavorites(this.song);

  @override
  List<Object?> get props => [song];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String songId;

  const RemoveFromFavorites(this.songId);

  @override
  List<Object?> get props => [songId];
}

class ClearFavoritesCache extends FavoritesEvent {}
