import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/repositories/favorites_repository.dart';
import 'package:play_beats/data/repositories/playlists_repository.dart';
import 'package:play_beats/data/repositories/song_metadata_repository.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_bloc.dart';
import 'package:play_beats/features/playlists/bloc/playlists_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_state.dart';
import 'package:play_beats/features/audios/bloc/audios_bloc.dart';
import 'package:play_beats/features/audios/bloc/audios_event.dart';
import 'package:play_beats/features/audios/bloc/audios_state.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';
import 'package:play_beats/features/audios/widgets/explore_album_art.dart';
import 'package:shimmer/shimmer.dart';

// ─── Diagonal cascade margins (fraction of screen width) ─────
const _margins  = [0.38, 0.22, 0.08, 0.02, 0.16, 0.28, 0.42];
const _artSizes = [50.0, 54.0, 48.0, 56.0, 52.0, 46.0, 44.0];

// ═════════════════════════════════════════════════════════════════
class AudiosScreen extends StatefulWidget {
  const AudiosScreen({super.key});

  @override
  State<AudiosScreen> createState() => _AudiosScreenState();
}

class _AudiosScreenState extends State<AudiosScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode  = FocusNode();
  final _scrollController = ScrollController();
  bool _showSearch = false;
  String _sortBy = 'title_asc'; // title_asc, title_desc, artist_asc, artist_desc, duration_asc, duration_desc

  // GlobalKey per list item — used to locate items for centering
  final Map<int, GlobalKey> _itemKeys = {};

  late final AnimationController _entryController;
  late final AnimationController _eqController;

  String? _lastCenteredSongId;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    context.read<AudiosBloc>().add(LoadAllAudios());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _entryController.dispose();
    _eqController.dispose();
    super.dispose();
  }

  // ── Scroll so the active item is vertically centered ─────────
  void _centerActiveItem(int activeIndex) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final key = _itemKeys[activeIndex];
      if (key?.currentContext == null) return;

      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box == null) return;

      // Position of item relative to the scroll view's RenderBox
      final scrollBox =
      _scrollController.position.context.storageContext.findRenderObject()
      as RenderBox?;
      if (scrollBox == null) return;

      final itemOffset = box.localToGlobal(Offset.zero, ancestor: scrollBox);
      final itemH      = box.size.height;
      final viewportH  = _scrollController.position.viewportDimension;
      final current    = _scrollController.offset;

      // Target: item center aligns with viewport center
      final target  = current + itemOffset.dy + itemH / 2 - viewportH / 2;
      final clamped = target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (_showSearch) {
      _searchFocusNode.requestFocus();
    } else {
      _searchFocusNode.unfocus();
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        context.read<AudiosBloc>().add(ClearSearch());
      }
    }
  }

  void _showSortOptions() {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  children: [
                    Icon(Icons.sort, color: c.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Sort By',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSortOption(sheetCtx, 'Title A to Z', 'title_asc', Icons.sort_by_alpha, true),
              _buildSortOption(sheetCtx, 'Title Z to A', 'title_desc', Icons.sort_by_alpha, false),
              _buildSortOption(sheetCtx, 'Artist A to Z', 'artist_asc', Icons.person, true),
              _buildSortOption(sheetCtx, 'Artist Z to A', 'artist_desc', Icons.person, false),
              _buildSortOption(sheetCtx, 'Duration (Shortest)', 'duration_asc', Icons.access_time, true),
              _buildSortOption(sheetCtx, 'Duration (Longest)', 'duration_desc', Icons.access_time, false),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext sheetCtx, String label, String value, IconData icon, bool isAscending) {
    final c = context.colors;
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? c.accent : c.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? c.accent : c.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: c.accent,
              size: 20,
            )
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(sheetCtx);
      },
    );
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? const [Color(0xFF0A0A18), Color(0xFF0F0F22), Color(0xFF131330)]
              : const [Color(0xFFE0E0EC), Color(0xFFE8E8F4), Color(0xFFF0F0FC)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchBar(),
            Expanded(
              child: BlocConsumer<AudiosBloc, AudiosState>(
                listener: (context, state) {
                  if (state is AudiosLoaded) {
                    _entryController.reset();
                    _entryController.forward();
                  }
                },
                builder: (context, state) {
                  if (state is AudiosLoading)        return _buildShimmer();
                  if (state is AudiosPermissionDenied) return _buildPermissionDenied();
                  if (state is AudiosError)           return _buildError(state.message);
                  if (state is AudiosLoaded) {
                    if (state.displayedSongs.isEmpty) {
                      return _buildEmpty(
                        state.searchQuery.isNotEmpty ? 'No songs found' : 'No songs on device',
                        state.searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Add music files to your device\nto see them here',
                      );
                    }
                    return _buildSongList(state.displayedSongs);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme-aware colors ────────────────────────────────────────
  Color get _textPrimary    => _isDark ? const Color(0xEBF0F0FF) : const Color(0xEB1A1A2E);
  Color get _textSecondary  => _isDark ? const Color(0x8CB4B4D2) : const Color(0x8C5A5A7E);
  Color get _activeCard     => _isDark ? const Color(0xFF252542) : Colors.white;
  Color get _activeBorder   => _isDark ? const Color(0x30FFFFFF) : const Color(0x14000000);
  Color get _iconAlpha      => _isDark
      ? Colors.white.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.4);
  Color get _subtleAlpha    => _isDark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.04);
  Color get _borderAlpha    => _isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);
  Color get _shimmerBase      => _isDark ? const Color(0xFF1C1C34) : const Color(0xFFD4D4E0);
  Color get _shimmerHighlight => _isDark ? const Color(0xFF282848) : const Color(0xFFE8E8F4);

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Audios',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Sort button
            GestureDetector(
              onTap: _showSortOptions,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _subtleAlpha,
                  border: Border.all(color: _borderAlpha),
                ),
                child: Icon(
                  Icons.sort,
                  color: _iconAlpha, size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search button
            GestureDetector(
              onTap: _toggleSearch,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _showSearch
                      ? _iconAlpha.withValues(alpha: 0.1)
                      : _subtleAlpha,
                  border: Border.all(color: _borderAlpha),
                ),
                child: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  color: _iconAlpha, size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _subtleAlpha,
          border: Border.all(color: _borderAlpha),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search songs, artists...',
            hintStyle: TextStyle(color: _iconAlpha.withValues(alpha: 0.4), fontSize: 14),
            prefixIcon:
            Icon(Icons.search, color: _iconAlpha.withValues(alpha: 0.4), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear,
                  color: _iconAlpha.withValues(alpha: 0.5), size: 18),
              onPressed: () {
                _searchController.clear();
                context.read<AudiosBloc>().add(ClearSearch());
                setState(() {});
              },
            )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (query) {
            setState(() {});
            if (query.isEmpty) {
              context.read<AudiosBloc>().add(ClearSearch());
            } else {
              context.read<AudiosBloc>().add(SearchAudios(query));
            }
          },
        ),
      ),
    );
  }

  // ── Song list ───────────────────────────────────────────────
  Widget _buildSongList(List<Song> songs) {
    // Sort songs based on selected criteria
    final sortedSongs = List<Song>.from(songs);
    sortedSongs.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'title_asc':
          comparison = a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
          break;
        case 'title_desc':
          comparison = b.displayTitle.toLowerCase().compareTo(a.displayTitle.toLowerCase());
          break;
        case 'artist_asc':
          comparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case 'artist_desc':
          comparison = b.artist.toLowerCase().compareTo(a.artist.toLowerCase());
          break;
        case 'duration_asc':
          comparison = a.duration.compareTo(b.duration);
          break;
        case 'duration_desc':
          comparison = b.duration.compareTo(a.duration);
          break;
        default:
          comparison = a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
      }
      return comparison;
    });

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final currentSongId = playerState.currentSong?.id;
        final isPlaying     = playerState is PlayerPlaying;
        final activeIndex   = sortedSongs.indexWhere((s) => s.id == currentSongId);

        // Trigger centering whenever the playing song changes
        if (currentSongId != null &&
            currentSongId != _lastCenteredSongId &&
            activeIndex != -1) {
          _lastCenteredSongId = currentSongId;
          _centerActiveItem(activeIndex);
        }

        return RefreshIndicator(
          color: _textPrimary,
          backgroundColor: _activeCard,
          onRefresh: () async => context.read<AudiosBloc>().add(RefreshAudios()),
          child: ListView.builder(
            controller: _scrollController,
            // Extra vertical padding so first/last items can scroll to center
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.38,
            ),
            itemCount: sortedSongs.length,
            itemBuilder: (context, index) {
              _itemKeys.putIfAbsent(index, () => GlobalKey());

              final delay = index * 0.06;
              final start = (0.1 + delay).clamp(0.0, 0.95);
              final end   = (start + 0.35).clamp(0.0, 1.0);

              final isActive     = sortedSongs[index].id == currentSongId;
              final isNowPlaying = isActive && isPlaying;

              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: Interval(start, end, curve: Curves.easeOut),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.45, 0.35),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _entryController,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  )),
                  child: _buildSongItem(
                    itemKey: _itemKeys[index]!,
                    song: sortedSongs[index],
                    index: index,
                    isActive: isActive,
                    isNowPlaying: isNowPlaying,
                    playlist: sortedSongs,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Mini EQ animation ────────────────────────────────────────
  Widget _buildMiniEq() {
    return AnimatedBuilder(
      animation: _eqController,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final h = 5.0 + sin(_eqController.value * pi + i * 1.2) * 5;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 3,
            height: h.clamp(3.0, 12.0),
            decoration: BoxDecoration(
              color: _textPrimary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }

  // ── Song item ──────────────────────────────────────────────
  Widget _buildSongItem({
    required GlobalKey itemKey,
    required Song song,
    required int index,
    required bool isActive,
    required bool isNowPlaying,
    required List<Song> playlist,
  }) {
    final p          = index % 7;
    final screenW    = MediaQuery.of(context).size.width;
    final marginLeft = _margins[p] * screenW;
    final artSize    = _artSizes[p];

    final art = ExploreAlbumArt(variant: p, size: artSize);

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                song.displayTitle,
                style: TextStyle(
                  fontSize: isActive ? 15 : 13.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? _textPrimary
                      : _textPrimary.withValues(alpha: 0.9),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (song.hasCustomTitle) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 12,
                color: _iconAlpha,
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          song.artist,
          style: TextStyle(
            fontSize: isActive ? 11.5 : 11,
            color: _textSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    // Play / Playing pill — right side of active card
    final playPill = GestureDetector(
      onTap: () {
        if (isNowPlaying) {
          context.read<PlayerBloc>().add(PauseSong());
        } else {
          context.read<PlayerBloc>()
              .add(PlaySong(song: song, playlist: playlist));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isNowPlaying) ...[
              _buildMiniEq(),
              const SizedBox(width: 7),
            ],
            Text(
              isNowPlaying ? 'Playing' : 'Play',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('${song.id}_$index'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isActive ? 50 : 28),
          color: Colors.green[700],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              'Rename',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isActive ? 50 : 28),
          color: Colors.red[700],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.delete, color: Colors.white, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Rename
          _showRenameDialog(context, song);
        } else {
          // Swipe left - Delete
          _showDeleteConfirmation(context, song);
        }
        return false; // Don't actually dismiss
      },
      child: GestureDetector(
        key: itemKey,
        onTap: () {
          context.read<PlayerBloc>().add(PlaySong(song: song, playlist: playlist));
          // Navigate to player screen after a short delay
          Future.delayed(const Duration(milliseconds: 20), () {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushNamed('/player');
          });
        },
        onLongPress: () => _showSongOptions(context, song, playlist),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        // Active: keep margin but extend to right edge for full-width card
        // Inactive: compact diagonal offset
        margin: EdgeInsets.only(
          left: isActive ? 16 : marginLeft,
          right: 16,
          bottom: isActive ? 10 : 7,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical:   isActive ? 10 : 7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isActive ? 50 : 28),
          color: isActive
              ? _activeCard
              : (_isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6)),
          border: Border.all(
            color: isActive
                ? _activeBorder
                : (_isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: _isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: _isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            art,
            const SizedBox(width: 12),
            Flexible(child: textColumn),
            if (isActive) ...[
              const SizedBox(width: 8),
              playPill,
            ],
          ],
        ),
        ),
      ),
    );
  }

  // ── Shimmer loading ─────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: 8,
        itemBuilder: (_, index) {
          final p       = index % 7;
          final screenW = MediaQuery.of(context).size.width;
          return Padding(
            padding: EdgeInsets.only(
                left: _margins[p] * screenW, right: 16, bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _artSizes[p], height: _artSizes[p],
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: _shimmerBase),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90, height: 12,
                      decoration: BoxDecoration(
                          color: _shimmerBase,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 55, height: 10,
                      decoration: BoxDecoration(
                          color: _shimmerBase,
                          borderRadius: BorderRadius.circular(5)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────
  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded,
              size: 64, color: _iconAlpha.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Permission denied ───────────────────────────────────────
  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_rounded,
              size: 64, color: _iconAlpha.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Permission Required',
              style: TextStyle(
                  color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('PlayBeats needs access to your\naudio files to play music',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.lock_open,
            label: 'Grant Permission',
            onTap: () => context.read<AudiosBloc>().add(LoadAllAudios()),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: _iconAlpha.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: TextStyle(
                  color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Retry',
            onTap: () => context.read<AudiosBloc>().add(LoadAllAudios()),
          ),
        ],
      ),
    );
  }

  // ── Shared action button ─────────────────────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _subtleAlpha.withValues(alpha: 0.06),
          border: Border.all(color: _borderAlpha),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _textPrimary, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Song options sheet ───────────────────────────────────────
  void _showSongOptions(BuildContext context, Song song, List<Song> playlist) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Rename
              ListTile(
                leading: Icon(Icons.edit, color: c.textPrimary),
                title: Text(
                  song.hasCustomTitle ? 'Edit Name' : 'Rename',
                  style: TextStyle(color: c.textPrimary),
                ),
                subtitle: song.hasCustomTitle
                    ? Text(
                        'Custom: ${song.displayTitle}',
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showRenameDialog(context, song);
                },
              ),
              // Add to playlist
              ListTile(
                leading: Icon(Icons.playlist_add, color: c.textPrimary),
                title: Text('Add to Playlist',
                    style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showAddToPlaylistSheet(context, song);
                },
              ),
              // Delete song
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                title: Text('Delete Song',
                    style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirmation(context, song);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Rename dialog ────────────────────────────────────────────
  void _showRenameDialog(BuildContext context, Song song) {
    final c = context.colors;
    final controller = TextEditingController(text: song.displayTitle);
    final metadataRepo = context.read<SongMetadataRepository>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Song', style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  hintStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.edit, color: c.iconDim),
                ),
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.done,
              ),
              if (song.hasCustomTitle) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: c.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original: ${song.title}',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (song.hasCustomTitle)
              TextButton(
                onPressed: () async {
                  await metadataRepo.clearCustomTitle(song.id);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored original name'),
                        backgroundColor: c.textSecondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('Reset', style: TextStyle(color: c.textSecondary)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != song.title) {
                  await metadataRepo.setCustomTitle(song.id, newName);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Renamed to "$newName"'),
                        backgroundColor: c.accent,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else if (newName.isEmpty) {
                  await metadataRepo.clearCustomTitle(song.id);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored original name'),
                        backgroundColor: c.textSecondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text('Save', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }

  // ── Add to playlist sheet ────────────────────────────────────
  void _showAddToPlaylistSheet(BuildContext context, Song song) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  children: [
                    Text('Select Playlist',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showCreatePlaylistDialog(context, song);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: c.accent, size: 16),
                            const SizedBox(width: 4),
                            Text('New',
                                style: TextStyle(
                                    color: c.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<PlaylistsBloc, PlaylistsState>(
                builder: (context, state) {
                  if (state is PlaylistsLoaded) {
                    if (state.playlists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No playlists yet.\nCreate one to add songs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = state.playlists[index];
                        final isSongInPlaylist =
                            playlist.songIds.contains(song.id);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: Neu.circular(
                              color: c.surface,
                              bgColor: c.background,
                              shadowDark: c.shadowDark,
                              shadowLight: c.shadowLight,
                            ),
                            child: Icon(Icons.queue_music,
                                color: c.textSecondary, size: 18),
                          ),
                          title: Text(
                            playlist.name,
                            style: TextStyle(color: c.textPrimary),
                          ),
                          subtitle: Text(
                            '${playlist.songIds.length} songs',
                            style: TextStyle(color: c.textSecondary),
                          ),
                          trailing: isSongInPlaylist
                              ? Icon(Icons.check, color: c.accent)
                              : null,
                          onTap: () {
                            if (!isSongInPlaylist) {
                              context.read<PlaylistsBloc>().add(
                                    AddSongToPlaylist(
                                      playlistId: playlist.id,
                                      songId: song.id,
                                    ),
                                  );
                            }
                            Navigator.pop(sheetCtx);
                          },
                        );
                      },
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Create playlist dialog ───────────────────────────────────
  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    final c = context.colors;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Playlist', style: TextStyle(color: c.textPrimary)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: c.textSecondary),
              filled: true,
              fillColor: c.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context
                      .read<PlaylistsBloc>()
                      .add(CreatePlaylist(controller.text.trim()));
                  Navigator.pop(dialogCtx);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (context.mounted) {
                      _showAddToPlaylistSheet(context, song);
                    }
                  });
                }
              },
              child: Text('Create', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }

  // ── Delete confirmation ──────────────────────────────────────
  void _showDeleteConfirmation(BuildContext context, Song song) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.warning_amber_rounded,
              color: Colors.red[400], size: 48),
          title: Text('Delete Song?', style: TextStyle(color: c.textPrimary)),
          content: Text(
            'This will permanently delete "${song.displayTitle}" from your device. This action cannot be undone.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _deleteSong(context, song);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          ],
        );
      },
    );
  }

  // ── Delete song file ─────────────────────────────────────────
  Future<void> _deleteSong(BuildContext context, Song song) async {
    final c = context.colors;
    
    try {
      final file = File(song.filePath);
      
      // Read repositories before async gaps
      final metadataRepo = context.read<SongMetadataRepository>();
      final favoritesRepo = context.read<FavoritesRepository>();
      final playlistsRepo = context.read<PlaylistsRepository>();
      
      // Check Android version for permissions
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // For Android 11+, check MANAGE_EXTERNAL_STORAGE permission
      if (sdkInt >= 30) {
        final manageStatus = await Permission.manageExternalStorage.status;
        
        if (manageStatus.isDenied || manageStatus.isPermanentlyDenied) {
          // Request permission
          final requested = await Permission.manageExternalStorage.request();
          
          if (!requested.isGranted) {
            if (!context.mounted) return;
            
            // Show dialog to open settings
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                backgroundColor: c.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                icon: Icon(Icons.folder_open, color: c.accent, size: 48),
                title: Text('Permission Required', style: TextStyle(color: c.textPrimary)),
                content: Text(
                  'To delete songs, please enable "All Files Access" permission in Settings.\n\n'
                  'Tap "Open Settings" and toggle "Allow access to manage all files".',
                  style: TextStyle(color: c.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await openAppSettings();
                    },
                    child: Text('Open Settings', style: TextStyle(color: c.accent)),
                  ),
                ],
              ),
            );
            return;
          }
        }
      }
      
      // Check if file exists
      final exists = await file.exists();
      debugPrint('Song file exists: $exists, path: ${song.filePath}');
      
      if (exists) {
        // Try to delete the file
        await file.delete();
        debugPrint('Song file deleted successfully');
        
        // Remove from favorites if present
        if (favoritesRepo.isFavorite(song.id)) {
          await favoritesRepo.removeFavorite(song.id);
        }
        
        // Remove from all playlists
        final allPlaylists = playlistsRepo.getAllPlaylists();
        for (final playlist in allPlaylists) {
          if (playlist.songIds.contains(song.id)) {
            await playlistsRepo.removeSongFromPlaylist(playlist.id, song.id);
          }
        }
        
        // Clear custom title if exists
        await metadataRepo.clearCustomTitle(song.id);
        
        if (!context.mounted) return;

        // Refresh the songs list
        context.read<AudiosBloc>().add(RefreshAudios());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song file not found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting song: $e');
      
      if (!context.mounted) return;
      
      // Check if it's a permission error
      final isPermissionError = e.toString().contains('Permission denied') || 
                                e.toString().contains('EROFS');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermissionError 
                ? 'Permission denied. Please grant "All Files Access" in Settings.'
                : 'Failed to delete song: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
    }
  }
}