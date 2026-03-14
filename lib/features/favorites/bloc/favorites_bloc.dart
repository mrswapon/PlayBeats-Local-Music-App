import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/repositories/favorites_repository.dart';
import 'package:play_beats/features/favorites/bloc/favorites_event.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc({FavoritesRepository? repository})
      : _repository = repository ?? FavoritesRepository(),
        super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    final favorites = await _repository.getFavorites();
    emit(FavoritesLoaded(favorites));
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    await _repository.addFavorite(event.song);
    final favorites = await _repository.getFavorites();
    emit(FavoritesLoaded(favorites));
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    await _repository.removeFavorite(event.songId);
    final favorites = await _repository.getFavorites();
    emit(FavoritesLoaded(favorites));
  }
}
