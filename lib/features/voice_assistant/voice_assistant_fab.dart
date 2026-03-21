import 'package:flutter/material.dart';
import '../../../core/api/advisory_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceAssistantFab extends StatefulWidget {
  const VoiceAssistantFab({super.key});

  @override
  State<VoiceAssistantFab> createState() => _VoiceAssistantFabState();
}

class _VoiceAssistantFabState extends State<VoiceAssistantFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _listening = false;
  bool _loading = false;
  final List<_Message> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _animCtrl.forward();
      if (_messages.isEmpty) {
        _messages.add(_Message(
          text: 'Hello! I\'m your AI farming assistant. Ask me anything about crops, diseases, weather, or market prices.',
          isBot: true,
        ));
      }
    } else {
      _animCtrl.reverse();
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text.trim(), isBot: false));
      _loading = true;
    });
    _ctrl.clear();
    _scroll();

    try {
      final response = await AdvisoryService().ask(text.trim());
      if (mounted) {
        setState(() {
          _messages.add(_Message(text: response, isBot: true));
          _loading = false;
        });
        _scroll();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
            text: 'Sorry, I couldn\'t connect right now. Please try again.',
            isBot: true,
          ));
          _loading = false;
        });
        _scroll();
      }
    }
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Chat panel
        if (_open)
          ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 80, right: 16),
              width: 320,
              height: 420,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kisan AI Assistant',
                                style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                              Text('Ask me about farming',
                                style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _toggle,
                        ),
                      ],
                    ),
                  ),
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return const _TypingIndicator();
                        }
                        return _ChatBubble(message: _messages[i]);
                      },
                    ),
                  ),
                  // Quick suggestions
                  if (_messages.length <= 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          'Paddy diseases',
                          'Cotton price',
                          'Rain forecast',
                        ].map((s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(s, style: const TextStyle(fontSize: 11)),
                            onPressed: () => _send(s),
                            visualDensity: VisualDensity.compact,
                          ),
                        )).toList(),
                      ),
                    ),
                  // Input
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onSubmitted: _send,
                            decoration: InputDecoration(
                              hintText: 'Ask about crops, weather...',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _listening = !_listening),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _listening
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _listening ? Icons.mic : Icons.mic_none,
                              color: _listening ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _send(_ctrl.text),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // FAB
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: AppTheme.primary,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _open
                ? const Icon(Icons.close, key: ValueKey('close'), color: Colors.white)
                : const Icon(Icons.smart_toy, key: ValueKey('bot'), color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: message.isBot ? Colors.grey[100] : AppTheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isBot ? 4 : 16),
            bottomRight: Radius.circular(message.isBot ? 16 : 4),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 12,
            color: message.isBot ? Colors.grey[800] : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 8),
            SizedBox(
              width: 40, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Thinking...', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isBot;
  const _Message({required this.text, required this.isBot});
}
