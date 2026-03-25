import 'package:flutter/material.dart';
import '../../../core/api/advisory_service.dart';
import '../../../core/theme/app_theme.dart';

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, this.isUser);
}

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  final _suggestions = [
    'How to prevent paddy blast?',
    'Best fertilizer for wheat?',
    'Signs of nitrogen deficiency?',
    'When to irrigate tomato crop?',
  ];

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Message(question, true));
      _loading = true;
    });
    _scrollDown();

    try {
      final answer = await AdvisoryService().ask(question);
      setState(() => _messages.add(_Message(answer, false)));
    } catch (e) {
      setState(() => _messages.add(
        _Message('Sorry, I could not get a response. Please try again.', false)));
    } finally {
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Advisory')),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.smart_toy, size: 64, color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text('Ask anything about farming',
                        style: TextStyle(fontSize: 16, color: Colors.grey))),
                    const SizedBox(height: 24),
                    const Text('Suggestions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _ask(s),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                  color: AppTheme.secondary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s)),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final msg = _messages[i];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Text(msg.text,
                        style: TextStyle(
                          color: msg.isUser ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask a farming question...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _ask,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'advisory_fab',
                  onPressed: () => _ask(_ctrl.text),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
