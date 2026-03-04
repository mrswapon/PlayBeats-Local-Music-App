import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<Song> favorites;
  final Set<String> _favoriteIds;

  FavoritesLoaded(this.favorites)
      : _favoriteIds = {for (final song in favorites) song.id};

  bool isFavorite(String songId) {
    return _favoriteIds.contains(songId);
  }

  @override
  List<Object?> get props => [favorites];
}
