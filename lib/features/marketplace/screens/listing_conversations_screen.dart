import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/chat_service.dart';
import '../../../core/theme/app_theme.dart';
import 'chat_screen.dart';

class ListingConversationsScreen extends StatefulWidget {
  final int listingId;
  final String cropName;
  const ListingConversationsScreen({
    super.key,
    required this.listingId,
    required this.cropName,
  });

  @override
  State<ListingConversationsScreen> createState() => _ListingConversationsScreenState();
}

class _ListingConversationsScreenState extends State<ListingConversationsScreen> {
  final _service = ChatService();
  List<ConversationDto> _convs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getListingConversations(widget.listingId);
      if (mounted) setState(() { _convs = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buyers — ${widget.cropName}'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                ]))
              : _convs.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No buyer enquiries yet',
                        style: TextStyle(color: Colors.grey)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _convs.length,
                        itemBuilder: (_, i) {
                          final c = _convs[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                              child: Text(
                                c.buyerName.isNotEmpty ? c.buyerName[0].toUpperCase() : 'B',
                                style: const TextStyle(color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold)),
                            ),
                            title: Text(c.buyerName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: c.lastMessageText != null
                                ? Text(c.lastMessageText!,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12))
                                : const Text('No messages yet',
                                    style: TextStyle(color: Colors.grey, fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (c.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Text('${c.unreadCount}',
                                    style: const TextStyle(color: Colors.white,
                                      fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              if (c.lastMessageAt != null)
                                Text(_formatTime(c.lastMessageAt!),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ]),
                            onTap: () {
                              _service.markConversationRead(c.id);
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: c.id,
                                  otherPartyName: c.buyerName,
                                  cropName: widget.cropName,
                                ),
                              )).then((_) => _fetch());
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays == 0) return DateFormat('h:mm a').format(local);
    if (now.difference(local).inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(local);
  }
}
