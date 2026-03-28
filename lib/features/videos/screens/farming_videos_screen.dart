import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/video_service.dart';
import '../../../core/theme/app_theme.dart';
import 'video_player_screen.dart';

class FarmingVideosScreen extends StatefulWidget {
  /// Pre-filled crop when opened from a field detail screen.
  final String? initialCrop;
  /// Pre-filled field name for the subtitle.
  final String? fieldName;

  const FarmingVideosScreen({super.key, this.initialCrop, this.fieldName});

  @override
  State<FarmingVideosScreen> createState() => _FarmingVideosScreenState();
}

class _FarmingVideosScreenState extends State<FarmingVideosScreen> {
  final _service = VideoService();

  static const _topics = [
    ('All',         null,          Icons.apps_outlined),
    ('Irrigation',  'irrigation',  Icons.water_drop_outlined),
    ('Pest Control','pestcontrol', Icons.bug_report_outlined),
    ('Fertilizer',  'fertilizer',  Icons.science_outlined),
    ('Harvest',     'harvest',     Icons.agriculture_outlined),
    ('Soil Health', 'soilhealth',  Icons.grass_outlined),
    ('Market',      'market',      Icons.store_outlined),
    ('Nursery',     'nursery',     Icons.eco_outlined),
  ];

  static const _languages = [
    ('हिंदी',    'hi'),
    ('English', 'en'),
    ('తెలుగు',  'te'),
    ('தமிழ்',   'ta'),
    ('ಕನ್ನಡ',   'kn'),
    ('मराठी',   'mr'),
    ('ਪੰਜਾਬੀ',  'pa'),
  ];

  late String _crop;
  String? _topic;
  String _language = 'hi';
  List<VideoItemDto> _videos = [];
  String? _nextPageToken;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final _scrollCtrl = ScrollController();
  bool _isForYou = true; // default to personalized feed

  @override
  void initState() {
    super.initState();
    _crop = widget.initialCrop ?? 'farming';
    // If opened from a field detail, go straight to browse with that crop
    if (widget.initialCrop != null) _isForYou = false;
    _scrollCtrl.addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loadingMore && _nextPageToken != null) {
      _fetchMore();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final VideoSearchResult result;
      if (_isForYou) {
        result = await _service.getPersonalizedFeed(
          language: _language,
        );
      } else {
        result = await _service.getFarmingVideos(
          crop: _crop, topic: _topic, language: _language,
        );
      }
      setState(() {
        _videos = result.items;
        _nextPageToken = result.nextPageToken;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _fetchMore() async {
    if (_nextPageToken == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final VideoSearchResult result;
      if (_isForYou) {
        result = await _service.getPersonalizedFeed(
          language: _language,
          pageToken: _nextPageToken,
        );
      } else {
        result = await _service.getFarmingVideos(
          crop: _crop, topic: _topic, language: _language,
          pageToken: _nextPageToken,
        );
      }
      setState(() {
        _videos.addAll(result.items);
        _nextPageToken = result.nextPageToken;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  void _openVideo(int index) {
    VideoPlayerScreen.open(context, _videos, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farming Videos',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
            if (widget.fieldName != null)
              Text(widget.fieldName!,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _LanguageBar(
            selected: _language,
            languages: _languages,
            onSelect: (lang) {
              setState(() => _language = lang);
              _fetch(reset: true);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // For You / Browse toggle
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _TabChip(
                  label: 'For You',
                  icon: Icons.auto_awesome,
                  active: _isForYou,
                  onTap: () {
                    if (!_isForYou) {
                      setState(() => _isForYou = true);
                      _fetch(reset: true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: 'Browse',
                  icon: Icons.explore_outlined,
                  active: !_isForYou,
                  onTap: () {
                    if (_isForYou) {
                      setState(() => _isForYou = false);
                      _fetch(reset: true);
                    }
                  },
                ),
              ],
            ),
          ),

          // Topic chips (only in Browse mode)
          if (!_isForYou)
            _TopicBar(
              topics: _topics,
              selected: _topic,
              onSelect: (t) {
                setState(() => _topic = t);
                _fetch(reset: true);
              },
            ),

          // Crop search chip row (only in Browse mode, not from a field)
          if (!_isForYou && widget.initialCrop == null) ...[
            _CropBar(
              current: _crop,
              onSelect: (c) {
                setState(() => _crop = c);
                _fetch(reset: true);
              },
            ),
          ],

          // Video grid
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: () => _fetch(reset: true))
                    : _videos.isEmpty
                        ? const _EmptyView()
                        : RefreshIndicator(
                            color: AppTheme.primary,
                            onRefresh: () => _fetch(reset: true),
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(12),
                              itemCount: _videos.length + (_nextPageToken != null ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == _videos.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                          color: AppTheme.primary),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _VideoCard(
                                    video: _videos[i],
                                    onTap: () => _openVideo(i),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── For You / Browse tab chips ────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : AppTheme.primary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Topic chips ───────────────────────────────────────────────────────────────

class _TopicBar extends StatelessWidget {
  final List<(String, String?, IconData)> topics;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _TopicBar(
      {required this.topics, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, key, icon) = topics[i];
          final active = selected == key;
          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: active ? Colors.white : AppTheme.primary),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: active ? Colors.white : AppTheme.primary,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ],
            ),
            selected: active,
            onSelected: (_) => onSelect(key),
            backgroundColor: Colors.white,
            selectedColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ── Language tabs ─────────────────────────────────────────────────────────────

class _LanguageBar extends StatelessWidget {
  final String selected;
  final List<(String, String)> languages;
  final ValueChanged<String> onSelect;

  const _LanguageBar(
      {required this.selected,
      required this.languages,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (label, code) = languages[i];
          final active = selected == code;
          return GestureDetector(
            onTap: () => onSelect(code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? AppTheme.primary : Colors.white,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }
}

// ── Crop quick-select bar (shown on standalone screen) ────────────────────────

class _CropBar extends StatelessWidget {
  static const _crops = [
    'Farming', 'Paddy', 'Wheat', 'Cotton', 'Maize',
    'Sugarcane', 'Soybean', 'Tomato', 'Onion', 'Potato', 'Groundnut',
  ];

  final String current;
  final ValueChanged<String> onSelect;

  const _CropBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _crops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _crops[i];
          final active = current.toLowerCase() == c.toLowerCase();
          return GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? AppTheme.primary : Colors.grey.shade300),
              ),
              child: Text(c,
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }
}

// ── Video card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoItemDto video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play overlay — full width
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnailUrl.isNotEmpty
                          ? video.thumbnailUrl
                          : video.thumbnailFallback,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.video_library_outlined,
                                  color: Colors.grey))),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.grey))),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
                // Duration / Shorts badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('Shorts',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            // Title + channel below thumbnail
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.channelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No videos found',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 4),
            Text('Try a different crop or topic',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
}
