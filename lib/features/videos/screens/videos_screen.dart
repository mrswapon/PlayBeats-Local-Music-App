import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/repositories/song_metadata_repository.dart';
import 'package:play_beats/features/videos/bloc/videos_bloc.dart';
import 'package:play_beats/features/videos/bloc/videos_event.dart';
import 'package:play_beats/features/videos/bloc/videos_state.dart';
import 'package:play_beats/features/videos/screens/video_player_screen.dart';
import 'package:shimmer/shimmer.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearch = false;
  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  
  // ── Theme-aware colors ────────────────────────────────────────
  Color get _textPrimary    => _isDark ? const Color(0xEBF0F0FF) : const Color(0xEB1A1A2E);
  Color get _iconAlpha      => _isDark
      ? Colors.white.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.4);
  Color get _subtleAlpha    => _isDark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.04);
  Color get _borderAlpha    => _isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    context.read<VideosBloc>().add(LoadVideos());
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filteredVideos = _allVideos;
      }
    });
  }

  void _filterVideos(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        return video.displayTitle.toLowerCase().contains(lowercaseQuery) ||
            video.artist.toLowerCase().contains(lowercaseQuery) ||
            video.album.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

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
              'Videos',
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
            hintText: 'Search videos...',
            hintStyle: TextStyle(color: _iconAlpha.withValues(alpha: 0.4), fontSize: 14),
            prefixIcon:
            Icon(Icons.search, color: _iconAlpha.withValues(alpha: 0.4), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear,
                  color: _iconAlpha.withValues(alpha: 0.5), size: 18),
              onPressed: () {
                _searchController.clear();
                _filterVideos('');
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
            _filterVideos(query);
          },
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

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
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: BlocConsumer<VideosBloc, VideosState>(
                listener: (context, state) {
                  if (state is VideosLoaded) {
                    _allVideos = state.videos;
                    _filteredVideos = _allVideos;
                    _entryController.reset();
                    _entryController.forward();
                  }
                },
                builder: (context, state) {
                  if (state is VideosLoading) {
                    return _buildShimmer();
                  }

                  if (state is VideosPermissionDenied) {
                    return _buildPermissionDenied();
                  }

                  if (state is VideosError) {
                    return _buildError(state.message);
                  }

                  if (state is VideosLoaded) {
                    if (_filteredVideos.isEmpty) {
                      return _buildEmptyState(
                        _searchController.text.isNotEmpty
                            ? 'No videos found for "${_searchController.text}"'
                            : 'No videos found',
                      );
                    }
                    return _buildVideoList(_filteredVideos);
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

  Widget _buildVideoList(List<Video> videos) {
    return RefreshIndicator(
      color: context.colors.textPrimary,
      backgroundColor: context.colors.surface,
      onRefresh: () async {
        context.read<VideosBloc>().add(RefreshVideos());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final delay = index * 0.06;
          final start = (0.1 + delay).clamp(0.0, 0.95);
          final end = (start + 0.35).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FadeTransition(
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
                child: _buildVideoTile(videos[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoTile(Video video) {
    final c = context.colors;
    return Dismissible(
      key: ValueKey(video.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Rename
          _showRenameDialog(context, video);
        } else {
          // Swipe left - Delete
          _showDeleteConfirmation(context, video);
        }
        return false; // Don't actually dismiss
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(video: video),
            ),
          );
        },
        onLongPress: () => _showVideoOptions(context, video),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: Neu.raised(
            radius: 18,
            color: c.surface,
            shadowDark: c.shadowDark,
            shadowLight: c.shadowLight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with actual video thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 140,
                  height: 78,
                  color: c.background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Show thumbnail if available, otherwise show icon
                      if (video.thumbnailPath != null && video.thumbnailPath!.isNotEmpty)
                        Positioned.fill(
                          child: Image.file(
                            File(video.thumbnailPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.video_library,
                                size: 40,
                                color: c.iconDim,
                              );
                            },
                          ),
                        )
                      else
                        Icon(
                          Icons.video_library,
                          size: 40,
                          color: c.iconDim,
                        ),
                      // Duration badge
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.durationFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Play overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.0),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            video.displayTitle,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (video.hasCustomTitle) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 12,
                            color: c.iconDim,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.artist,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.album.isNotEmpty &&
                        video.album != 'Unknown Album') ...[
                      const SizedBox(height: 4),
                      Text(
                        video.album,
                        style: TextStyle(
                          color: c.iconDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    final c = context.colors;
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C34)
        : const Color(0xFFD4D4E0);
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF282848)
        : const Color(0xFFE8E8F4);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 78,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState([String? message]) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: Neu.circular(
              color: c.surface,
              bgColor: c.background,
              shadowDark: c.shadowDark,
              shadowLight: c.shadowLight,
            ),
            child: Icon(Icons.video_library_rounded,
                color: c.iconDim, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            message ?? 'No videos found',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message != null
                ? 'Try a different search term'
                : 'Add video files to your device\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_rounded,
              size: 64, color: c.iconDim.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Permission Required',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('PlayBeats needs access to your\nvideo files to play videos',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              context.read<VideosBloc>().add(LoadVideos());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04))
                    .withValues(alpha: 0.06),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: c.textPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: TextStyle(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: c.iconDim.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              context.read<VideosBloc>().add(LoadVideos());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04))
                    .withValues(alpha: 0.06),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: c.textPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: TextStyle(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Video options sheet ───────────────────────────────────────
  void _showVideoOptions(BuildContext context, Video video) {
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
                  video.hasCustomTitle ? 'Edit Name' : 'Rename',
                  style: TextStyle(color: c.textPrimary),
                ),
                subtitle: video.hasCustomTitle
                    ? Text(
                        'Custom: ${video.displayTitle}',
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showRenameDialog(context, video);
                },
              ),
              // Delete video
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                title: Text('Delete Video',
                    style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirmation(context, video);
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
  void _showRenameDialog(BuildContext context, Video video) {
    final c = context.colors;
    final controller = TextEditingController(text: video.displayTitle);
    final metadataRepo = context.read<SongMetadataRepository>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Video', style: TextStyle(color: c.textPrimary)),
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
              if (video.hasCustomTitle) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: c.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original: ${video.title}',
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
            if (video.hasCustomTitle)
              TextButton(
                onPressed: () async {
                  await metadataRepo.clearCustomTitle(video.id);
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
                if (newName.isNotEmpty && newName != video.title) {
                  await metadataRepo.setCustomTitle(video.id, newName);
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
                  await metadataRepo.clearCustomTitle(video.id);
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

  // ── Delete confirmation ──────────────────────────────────────
  void _showDeleteConfirmation(BuildContext context, Video video) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.warning_amber_rounded,
              color: Colors.red[400], size: 48),
          title: Text('Delete Video?', style: TextStyle(color: c.textPrimary)),
          content: Text(
            'This will permanently delete "${video.displayTitle}" from your device. This action cannot be undone.',
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
                await _deleteVideo(context, video);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          ],
        );
      },
    );
  }

  // ── Delete video file ────────────────────────────────────────
  Future<void> _deleteVideo(BuildContext context, Video video) async {
    final c = context.colors;
    
    try {
      final file = File(video.filePath);
      
      // Read repository before async gap
      final metadataRepo = context.read<SongMetadataRepository>();
      
      // Check Android version
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
                  'To delete videos, please enable "All Files Access" permission in Settings.\n\n'
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
      debugPrint('Video file exists: $exists, path: ${video.filePath}');
      
      if (exists) {
        // Try to delete the file
        await file.delete();
        debugPrint('Video file deleted successfully');
        
        // Clear custom title if exists
        await metadataRepo.clearCustomTitle(video.id);
        
        if (!context.mounted) return;
        
        // Refresh the video list
        context.read<VideosBloc>().add(RefreshVideos());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file not found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      
      if (!context.mounted) return;
      
      // Check if it's a permission error
      final isPermissionError = e.toString().contains('Permission denied') || 
                                e.toString().contains('EROFS');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermissionError 
                ? 'Permission denied. Please grant "All Files Access" in Settings.'
                : 'Failed to delete video: $e',
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
