import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/consultation_service.dart';
import '../../../core/theme/app_theme.dart';
import 'call_summary_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final ConsultationDto session;
  final String expertName;
  const VideoCallScreen({super.key, required this.session, required this.expertName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _consultationService = ConsultationService();

  // Agora
  RtcEngine? _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _localVideo = true;
  bool _localAudio = true;
  bool _frontCamera = true;
  bool _showNotes = false;

  // Call timer
  final _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsed = '00:00';

  // Notes
  final _noteController = TextEditingController();
  final _aiQuestionController = TextEditingController();
  final List<ConsultationNoteDto> _notes = [];
  bool _aiLoading = false;
  String? _aiResponse;

  // Session
  late ConsultationDto _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _initCall();
  }

  Future<void> _initCall() async {
    await [Permission.camera, Permission.microphone].request();
    await _initAgora();
    _startTimer();
    // Notify backend call started
    try {
      _session = await _consultationService.startCall(_session.id);
    } catch (_) {}
  }

  Future<void> _initAgora() async {
    // Get Agora App ID from config or use placeholder for demo
    const appId = 'YOUR_AGORA_APP_ID'; // Will be read from config in production

    if (appId.contains('YOUR_')) {
      // Demo mode — no Agora, just show UI
      setState(() => _joined = true);
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        setState(() => _joined = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() => _remoteUid = null);
      },
    ));

    await _engine!.enableVideo();
    await _engine!.startPreview();
    await _engine!.joinChannel(
      token: _session.agoraToken ?? '',
      channelId: _session.channelName ?? 'demo',
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = _stopwatch.elapsed;
      setState(() {
        _elapsed = '${s.inMinutes.toString().padLeft(2, '0')}:'
            '${(s.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
    setState(() => _frontCamera = !_frontCamera);
  }

  Future<void> _toggleVideo() async {
    _localVideo = !_localVideo;
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(!_localVideo);
    }
    setState(() {});
  }

  Future<void> _toggleAudio() async {
    _localAudio = !_localAudio;
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(!_localAudio);
    }
    setState(() {});
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    _noteController.clear();
    try {
      final note = await _consultationService.addNote(_session.id, text);
      setState(() => _notes.add(note));
    } catch (_) {
      // Offline note
      setState(() => _notes.add(ConsultationNoteDto(
        id: 0, authorUserId: '', authorRole: 'Farmer',
        content: text, createdAt: DateTime.now(),
      )));
    }
  }

  Future<void> _askAi() async {
    final q = _aiQuestionController.text.trim();
    if (q.isEmpty) return;
    setState(() { _aiLoading = true; _aiResponse = null; });
    try {
      final response = await _consultationService.getAiSuggestion(_session.id, q);
      setState(() { _aiResponse = response; _aiLoading = false; });
      // Also save AI response as a note
      _notes.add(ConsultationNoteDto(
        id: 0, authorUserId: 'AI', authorRole: 'AI',
        content: 'Q: $q\nA: $response', createdAt: DateTime.now(),
      ));
    } catch (e) {
      setState(() {
        _aiResponse = 'AI is not available right now. Please consult with the expert directly.';
        _aiLoading = false;
      });
    }
    _aiQuestionController.clear();
  }

  Future<void> _endCall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Call?'),
        content: const Text('AI will generate a summary of your consultation notes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    _stopwatch.stop();
    _timer?.cancel();

    ConsultationDto? endedSession;
    try {
      endedSession = await _consultationService.endCall(_session.id);
    } catch (_) {}

    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallSummaryScreen(
            session: endedSession ?? _session,
            notes: _notes,
            duration: _elapsed,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _engine?.leaveChannel();
    _engine?.release();
    _noteController.dispose();
    _aiQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_remoteUid != null && _engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: _session.channelName ?? 'demo'),
              ),
            )
          else
            // Placeholder when no remote video
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      widget.expertName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.expertName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_joined ? 'Waiting for expert to join...' : 'Connecting...',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                ],
              ),
            ),

          // Local video (picture-in-picture)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.grey[900],
                ),
                clipBehavior: Clip.antiAlias,
                child: _localVideo && _engine != null
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_localVideo ? Icons.videocam : Icons.videocam_off,
                              color: Colors.white54, size: 30),
                          const SizedBox(height: 4),
                          Text(_frontCamera ? 'Front' : 'Rear',
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 2),
                          const Text('Tap to switch', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        ],
                      ),
              ),
            ),
          ),

          // Top bar — timer + info
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(_elapsed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(widget.session.cropType ?? '',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                ],
              ),
            ),
          ),

          // Notes panel (slide up)
          if (_showNotes)
            Positioned(
              bottom: 100,
              left: 0, right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    // Tab header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.notes, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          const Text('Session Notes & AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _showNotes = false),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Notes list
                    Expanded(
                      child: _notes.isEmpty
                          ? const Center(child: Text('No notes yet. Add notes or ask AI below.',
                              style: TextStyle(color: Colors.grey, fontSize: 12)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: _notes.length,
                              itemBuilder: (_, i) {
                                final n = _notes[i];
                                final isAi = n.authorRole == 'AI';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAi ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isAi ? Border.all(color: Colors.amber.withValues(alpha: 0.3)) : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(isAi ? Icons.smart_toy : Icons.person,
                                              size: 14, color: isAi ? Colors.amber[700] : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(n.authorRole,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                                  color: isAi ? Colors.amber[700] : Colors.grey)),
                                          const Spacer(),
                                          Text('${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(n.content, style: const TextStyle(fontSize: 12, height: 1.4)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    // AI response
                    if (_aiResponse != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.smart_toy, size: 16, color: Colors.amber),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_aiResponse!, style: const TextStyle(fontSize: 12, height: 1.4))),
                          ],
                        ),
                      ),
                    // Input row — notes + AI
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          // Note input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _noteController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Add a note...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onSubmitted: (_) => _addNote(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.send, color: AppTheme.primary, size: 20),
                                onPressed: _addNote,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // AI question input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _aiQuestionController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Ask AI assistant...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                    prefixIcon: const Icon(Icons.smart_toy, size: 18),
                                  ),
                                  onSubmitted: (_) => _askAi(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _aiLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : IconButton(
                                      icon: Icon(Icons.auto_awesome, color: Colors.amber[700], size: 20),
                                      onPressed: _askAi,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 20,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: _localAudio ? Icons.mic : Icons.mic_off,
                  label: _localAudio ? 'Mute' : 'Unmute',
                  color: _localAudio ? Colors.white24 : Colors.red,
                  onTap: _toggleAudio,
                ),
                _CallButton(
                  icon: _localVideo ? Icons.videocam : Icons.videocam_off,
                  label: _localVideo ? 'Video Off' : 'Video On',
                  color: _localVideo ? Colors.white24 : Colors.red,
                  onTap: _toggleVideo,
                ),
                _CallButton(
                  icon: Icons.cameraswitch,
                  label: _frontCamera ? 'Rear Cam' : 'Front Cam',
                  color: Colors.white24,
                  onTap: _switchCamera,
                ),
                _CallButton(
                  icon: Icons.notes,
                  label: 'Notes',
                  color: _showNotes ? AppTheme.primary : Colors.white24,
                  onTap: () => setState(() => _showNotes = !_showNotes),
                ),
                _CallButton(
                  icon: Icons.call_end,
                  label: 'End',
                  color: Colors.red,
                  onTap: _endCall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CallButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    ),
  );
}
