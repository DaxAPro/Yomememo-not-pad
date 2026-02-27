import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/snow_animation_widget.dart';
import '../widgets/sakura_animation_widget.dart';
import '../widgets/magical_text_animation.dart';
import '../widgets/notes_layout_builder.dart';
import '../widgets/magical_text_animation.dart';
import '../widgets/glowing_empty_state.dart';
import 'note_editor_screen.dart';
import 'side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Safe handling of BannerAd to prevent crashes during disposal
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  late TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _debounce;

  late VideoPlayerController _videoController;
  late AnimationController _colorAnimationController;

  NoteViewStyle _currentStyle = NoteViewStyle.staggered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSortOrder =
          Provider.of<NoteProvider>(context, listen: false).sortOrder;
      Provider.of<NoteProvider>(context, listen: false)
          .setSortOrder(currentSortOrder);
    });

    _loadBannerAd();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _videoController = VideoPlayerController.asset(
      'assets/videos/night_sky.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
          _videoController.setLooping(true);
          _videoController.setVolume(0);
        }
      }).catchError((error) {
        debugPrint("Video Load Error: $error");
      });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.toLowerCase());
      }
    });
  }

  Future<void> _navigateWithPause(Widget page) async {
    if (_videoController.value.isInitialized) _videoController.pause();
    _colorAnimationController.stop();

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => page));

    if (mounted) {
      if (_videoController.value.isInitialized) _videoController.play();
      _colorAnimationController.repeat(reverse: true);
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6724714162464767/2958351464',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Ad failed to load: $err');
          _isBannerAdReady = false;
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd?.load();
  }

  void _showNoteOptionsDialog(BuildContext context, Note note) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note to Top'),
                onTap: () {
                  noteProvider.togglePinNote(note);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Move to Trash',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  noteProvider.moveToTrash(note);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _colorAnimationController.dispose();
    _bannerAd?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildAnimationWidget(String type) {
    switch (type) {
      case 'Snow':
        return const SnowAnimationWidget(key: ValueKey('Snow'));
      case 'Sakura':
        return const SakuraAnimationWidget(key: ValueKey('Sakura'));
      case 'Butterfly':
        return const ButterflyAnimationWidget(key: ValueKey('Butterfly'));
      case 'None':
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    List<Note> filteredNotes = noteProvider.notes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(_searchQuery) ||
          note.content.toLowerCase().contains(_searchQuery);
    }).toList();

    final baseColor = themeProvider.appColor;
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor lighterColor =
        hslColor.withLightness((hslColor.lightness + 0.1).clamp(0.0, 1.0));
    final endColor = lighterColor.toColor();

    final colorAnimation = ColorTween(
      begin: baseColor,
      end: endColor,
    ).animate(_colorAnimationController);

    ImageProvider? bgImage;
    if (themeProvider.backgroundImage != null) {
      if (themeProvider.isAssetImage) {
        bgImage = AssetImage(themeProvider.backgroundImage!);
      } else if (kIsWeb) {
        bgImage = NetworkImage(themeProvider.backgroundImage!);
      } else {
        bgImage = FileImage(File(themeProvider.backgroundImage!));
      }
    }

    return AnimatedBuilder(
      animation: _colorAnimationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            foregroundColor: Colors.white,
            backgroundColor: isDarkMode ? null : colorAnimation.value,
            title: const MagicalTextAnimation(
              text: 'YumeMemo 🎀',
              fontSize: 32,
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _currentStyle == NoteViewStyle.staggered
                      ? Icons.view_agenda
                      : _currentStyle == NoteViewStyle.list
                          ? Icons.grid_view
                          : Icons.dashboard,
                  color: Colors.white,
                ),
                tooltip: 'Change View Style',
                onPressed: () {
                  setState(() {
                    if (_currentStyle == NoteViewStyle.staggered) {
                      _currentStyle = NoteViewStyle.list;
                    } else if (_currentStyle == NoteViewStyle.list) {
                      _currentStyle = NoteViewStyle.grid;
                    } else {
                      _currentStyle = NoteViewStyle.staggered;
                    }
                  });
                },
              ),
              PopupMenuButton<SortOrder>(
                icon: const Icon(Icons.swap_vert, color: Colors.white),
                tooltip: 'Sort Notes',
                onSelected: (SortOrder newOrder) {
                  noteProvider.setSortOrder(newOrder);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SortOrder>>[
                  const PopupMenuItem<SortOrder>(
                    value: SortOrder.dateDesc,
                    child: Text('Newest First'),
                  ),
                  const PopupMenuItem<SortOrder>(
                    value: SortOrder.dateAsc,
                    child: Text('Oldest First'),
                  ),
                  const PopupMenuItem<SortOrder>(
                    value: SortOrder.titleAsc,
                    child: Text('Title (A-Z)'),
                  ),
                  const PopupMenuItem<SortOrder>(
                    value: SortOrder.titleDesc,
                    child: Text('Title (Z-A)'),
                  ),
                ],
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56.0),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                      prefixIcon: Icon(Icons.search,
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none),
                      fillColor: isDarkMode
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.7),
                      filled: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
            ),
          ),
          body: child,
          drawer: const SideMenu(),
          bottomNavigationBar: _isBannerAdReady && _bannerAd != null
              ? SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              : const SizedBox.shrink(),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateWithPause(const NoteEditorScreen()),
            child: const Icon(Icons.add),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: bgImage != null
                  ? DecorationImage(
                      image: bgImage,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          _buildAnimationWidget(themeProvider.animationType),
          SafeArea(
            child: (noteProvider.isLoading && noteProvider.notes.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? const GlowingEmptyState()
                    : NotesLayoutBuilder(
                        notes: filteredNotes,
                        viewStyle: _currentStyle,
                        searchQuery: _searchQuery,
                        isDarkMode: isDarkMode,
                        onNoteTap: (note) =>
                            _navigateWithPause(NoteEditorScreen(note: note)),
                        onNoteLongPress: (note) =>
                            _showNoteOptionsDialog(context, note),
                      ),
          ),
        ],
      ),
    );
  }
}
