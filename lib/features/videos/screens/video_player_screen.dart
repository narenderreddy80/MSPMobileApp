import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/video_service.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoItemDto video;

  const VideoPlayerScreen({super.key, required this.video});

  static void open(BuildContext context, VideoItemDto video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final shortsUrl = 'https://www.youtube.com/shorts/${widget.video.videoId}';
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        // Block navigation away from Shorts — keep user inside the player
        onNavigationRequest: (request) {
          final url = request.url;
          // Allow the initial Shorts URL and YouTube consent/login pages
          if (url.contains('youtube.com/shorts/') ||
              url.contains('consent.youtube.com') ||
              url.contains('accounts.google.com')) {
            return NavigationDecision.navigate;
          }
          // Block everything else (recommendations, channel pages, etc.)
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(shortsUrl));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _ctrl),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}
