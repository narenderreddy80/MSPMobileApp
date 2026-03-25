import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../core/api/listing_service.dart';
import '../../../core/api/chat_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rating_widgets.dart';
import 'chat_screen.dart';
import 'listing_conversations_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _listingService = ListingService();
  final _chatService = ChatService();
  ListingDetailDto? _listing;
  bool _loading = true;
  String? _error;
  bool _contactLoading = false;
  int _imageIndex = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: AppConstants.userIdKey);
      final data = await _listingService.getDetail(widget.listingId);
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _listing = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAsSold(int id) async {
    await _listingService.updateStatus(id, 'Sold');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as Sold')));
    Navigator.pop(context, true);
  }

  Future<void> _removeListing(int id) async {
    await _listingService.updateStatus(id, 'Removed');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing removed')));
    Navigator.pop(context, true);
  }

  Future<void> _contactFarmer() async {
    setState(() => _contactLoading = true);
    try {
      final conv = await _chatService.getOrCreateConversation(widget.listingId);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id,
          otherPartyName: _listing!.sellerName,
          cropName: _listing!.cropName,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _contactLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
        ]),
      ));
    }

    final d = _listing!;
    final isOwner = _currentUserId != null && _currentUserId == d.sellerUserId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: d.imageUrls.isEmpty
                  ? Container(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.grass, size: 80, color: AppTheme.primary))
                  : Stack(fit: StackFit.expand, children: [
                      PageView.builder(
                        itemCount: d.imageUrls.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          d.imageUrls[i], fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.grass, size: 80, color: AppTheme.primary)),
                        ),
                      ),
                      if (d.imageUrls.length > 1)
                        Positioned(
                          bottom: 12, left: 0, right: 0,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(d.imageUrls.length, (i) =>
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _imageIndex == i ? 10 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _imageIndex == i ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(3)),
                              )),
                          ),
                        ),
                    ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Crop name + price
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(d.cropName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\u20b9${d.pricePerUnit.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.secondary)),
                  Text('per ${d.quantityUnit}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 8),
              // Chips
              Wrap(spacing: 8, children: [
                if (d.variety.isNotEmpty)
                  Chip(label: Text(d.variety),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                    labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 12),
                    padding: EdgeInsets.zero),
                Chip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                  label: Text('${d.quantityValue.toStringAsFixed(0)} ${d.quantityUnit}'),
                  backgroundColor: Colors.grey[100],
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero),
              ]),
              const SizedBox(height: 12),
              // Location
              Row(children: [
                const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text('${d.district}, ${d.state}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 12),
              // Notes
              if (d.notes != null && d.notes!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.notes, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(d.notes!, style: const TextStyle(fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 8),
              // Seller info
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(d.sellerName.isNotEmpty ? d.sellerName[0].toUpperCase() : 'F',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.sellerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Listed ${DateFormat('d MMM y').format(d.createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              // ── Seller reviews ──────────────────────────────────
              UserReviewsSection(
                userId: d.sellerUserId,
                userName: d.sellerName,
                showRateButton: !isOwner,
                currentUserId: _currentUserId,
              ),
              const SizedBox(height: 80),
            ])),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: isOwner
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: d.status == 'Active' ? () => _markAsSold(d.id) : null,
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Mark as Sold'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: d.status != 'Removed' ? () => _removeListing(d.id) : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ListingConversationsScreen(
                          listingId: d.id,
                          cropName: d.cropName,
                        ),
                      )),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('View Buyer Conversations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ])
              : ElevatedButton.icon(
                  onPressed: _contactLoading ? null : _contactFarmer,
                  icon: _contactLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat_bubble_outline),
                  label: Text(_contactLoading ? 'Opening Chat...' : 'Contact Farmer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
