import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/chat_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String otherPartyName;
  final String cropName;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPartyName,
    required this.cropName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _apiClient = ApiClient();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  List<MessageDto> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final token = await _apiClient.token;
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = _base64PadRight(parts[1]);
          final decoded = utf8.decode(base64Url.decode(payload));
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          final sub = map['sub'] as String?;
          if (sub != null && mounted) {
            setState(() => _currentUserId = sub);
          }
        }
      } catch (_) {}
    }
  }

  String _base64PadRight(String s) {
    final pad = s.length % 4;
    if (pad == 0) return s;
    return s + ('=' * (4 - pad));
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _service.getMessages(widget.conversationId);
      if (mounted) {
        setState(() { _messages = msgs; _loading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      final msg = await _service.sendMessage(widget.conversationId, text);
      if (mounted) {
        setState(() => _messages.add(msg));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otherPartyName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(widget.cropName,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No messages yet'),
                      const SizedBox(height: 6),
                      Text('Say hello to ${widget.otherPartyName}!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ]))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _MessageBubble(
                        msg: _messages[i],
                        isOwn: _messages[i].senderUserId == _currentUserId,
                      ),
                    ),
        ),
        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                color: AppTheme.secondary,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDto msg;
  final bool isOwn;
  const _MessageBubble({required this.msg, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary,
                      fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOwn ? AppTheme.primary : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isOwn ? 16 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 16),
                    ),
                  ),
                  child: Text(msg.text,
                    style: TextStyle(
                      color: isOwn ? Colors.white : Colors.black87,
                      fontSize: 14)),
                ),
              ),
              if (isOwn) const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isOwn ? 0 : 34,
              right: isOwn ? 6 : 0),
            child: Text(
              DateFormat('h:mm a').format(msg.sentAt.toLocal()),
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}
