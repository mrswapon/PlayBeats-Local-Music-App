import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/songs/bloc/songs_bloc.dart';
import 'package:play_beats/features/songs/bloc/songs_event.dart';
import 'package:play_beats/features/songs/bloc/songs_state.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';
import 'package:play_beats/features/songs/widgets/explore_album_art.dart';
import 'dart:math';
import 'package:shimmer/shimmer.dart';

// ─── Diagonal cascade margins (fraction of screen width) ─────
const _margins  = [0.38, 0.22, 0.08, 0.02, 0.16, 0.28, 0.42];
const _artSizes = [50.0, 54.0, 48.0, 56.0, 52.0, 46.0, 44.0];

// ═════════════════════════════════════════════════════════════════
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode  = FocusNode();
  final _scrollController = ScrollController();
  bool _showSearch = false;

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
    context.read<SongsBloc>().add(LoadAllSongs());
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
        context.read<SongsBloc>().add(ClearSearch());
      }
    }
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
              child: BlocConsumer<SongsBloc, SongsState>(
                listener: (context, state) {
                  if (state is SongsLoaded) {
                    _entryController.reset();
                    _entryController.forward();
                  }
                },
                builder: (context, state) {
                  if (state is SongsLoading)        return _buildShimmer();
                  if (state is SongsPermissionDenied) return _buildPermissionDenied();
                  if (state is SongsError)           return _buildError(state.message);
                  if (state is SongsLoaded) {
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
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Songs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
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
                context.read<SongsBloc>().add(ClearSearch());
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
              context.read<SongsBloc>().add(ClearSearch());
            } else {
              context.read<SongsBloc>().add(SearchSongs(query));
            }
          },
        ),
      ),
    );
  }

  // ── Song list ───────────────────────────────────────────────
  Widget _buildSongList(List<Song> songs) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final currentSongId = playerState.currentSong?.id;
        final isPlaying     = playerState is PlayerPlaying;
        final activeIndex   = songs.indexWhere((s) => s.id == currentSongId);

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
          onRefresh: () async => context.read<SongsBloc>().add(RefreshSongs()),
          child: ListView.builder(
            controller: _scrollController,
            // Extra vertical padding so first/last items can scroll to center
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.38,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              _itemKeys.putIfAbsent(index, () => GlobalKey());

              final delay = index * 0.06;
              final start = (0.1 + delay).clamp(0.0, 0.95);
              final end   = (start + 0.35).clamp(0.0, 1.0);

              final isActive     = songs[index].id == currentSongId;
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
                    song: songs[index],
                    index: index,
                    isActive: isActive,
                    isNowPlaying: isNowPlaying,
                    playlist: songs,
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
        Text(
          song.title,
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

    return GestureDetector(
      key: itemKey,
      onTap: () => context.read<PlayerBloc>()
          .add(PlaySong(song: song, playlist: playlist)),
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
            onTap: () => context.read<SongsBloc>().add(LoadAllSongs()),
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
            onTap: () => context.read<SongsBloc>().add(LoadAllSongs()),
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
}