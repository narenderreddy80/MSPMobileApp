import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/video_service.dart';
import '../../../core/theme/app_theme.dart';

/// Opens the player with swipe-left/right navigation across [videos],
/// starting at [initialIndex].
class VideoPlayerScreen extends StatefulWidget {
  final List<VideoItemDto> videos;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  // Convenience constructor for a single video (backwards compat)
  static VideoPlayerScreen single(VideoItemDto video) =>
      VideoPlayerScreen(videos: [video]);

  static void open(
    BuildContext context,
    List<VideoItemDto> videos,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerScreen(videos: videos, initialIndex: index),
      ),
    );
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.videos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.videos[_currentIndex].title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (total > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / $total',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) =>
                _VideoPage(video: widget.videos[i], active: i == _currentIndex),
          ),
          // Swipe hint arrows (shown only when more videos exist)
          if (total > 1) ...[
            if (_currentIndex > 0)
              const Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.chevron_left,
                      color: Colors.white38, size: 36),
                ),
              ),
            if (_currentIndex < total - 1)
              const Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.chevron_right,
                      color: Colors.white38, size: 36),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Single video page ─────────────────────────────────────────────────────────

class _VideoPage extends StatefulWidget {
  final VideoItemDto video;
  final bool active;

  const _VideoPage({required this.video, required this.active});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final WebViewController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.contains('youtube.com/shorts/') ||
              url.contains('consent.youtube.com') ||
              url.contains('accounts.google.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(
          'https://www.youtube.com/shorts/${widget.video.videoId}'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _ctrl)),
        if (_loading)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
      ],
    );
  }
}
