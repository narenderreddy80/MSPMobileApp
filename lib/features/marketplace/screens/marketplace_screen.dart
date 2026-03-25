import 'package:flutter/material.dart';
import '../../../core/api/listing_service.dart';
import '../../../core/theme/app_theme.dart';
import 'listing_detail_screen.dart';
import 'create_listing_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marketplace'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Browse'),
              Tab(text: 'My Listings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BrowseTab(),
            _MyListingsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Browse Tab ────────────────────────────────────────────────────────────────

class _BrowseTab extends StatefulWidget {
  const _BrowseTab();
  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final _service = ListingService();
  final _cropCtrl = TextEditingController();
  final _minCtrl  = TextEditingController();
  final _maxCtrl  = TextEditingController();
  String _selectedState = '';
  List<ListingSummaryDto> _items = [];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  static const _pageSize = 20;
  late final ScrollController _scroll;

  final _states = ['', 'Andhra Pradesh', 'Karnataka', 'Kerala', 'Maharashtra',
    'Madhya Pradesh', 'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana',
    'Uttar Pradesh', 'West Bengal'];

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _cropCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore && _items.length < _total) {
      _fetch(reset: false);
    }
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _items = []; });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await _service.browse(
        cropName: _cropCtrl.text.trim().isEmpty ? null : _cropCtrl.text.trim(),
        state: _selectedState.isEmpty ? null : _selectedState,
        minPrice: double.tryParse(_minCtrl.text),
        maxPrice: double.tryParse(_maxCtrl.text),
        limit: _pageSize,
        offset: reset ? 0 : _items.length,
      );
      if (!mounted) return;
      setState(() {
        _total = result.total;
        if (reset) {
          _items = result.items;
        } else {
          _items = [..._items, ...result.items];
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() { _loading = false; _loadingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter bar
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _cropCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search crop...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _fetch(reset: true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Search'),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedState,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: _states.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.isEmpty ? 'All States' : s, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedState = v ?? ''),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min \u20b9',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max \u20b9',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ]),
        ]),
      ),
      // Status bar
      Container(
        color: AppTheme.primary.withValues(alpha: 0.07),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(children: [
          const Icon(Icons.storefront, size: 13, color: AppTheme.primary),
          const SizedBox(width: 5),
          const Text('Fresh produce \u00b7 direct from farmers',
            style: TextStyle(fontSize: 11, color: AppTheme.primary)),
          const Spacer(),
          if (_total > 0)
            Text('$_total listings',
              style: const TextStyle(fontSize: 11, color: AppTheme.primary,
                fontWeight: FontWeight.bold)),
        ]),
      ),
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _fetch(reset: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ]));
    }
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.grass, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('No listings found'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _fetch(reset: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ]));
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ListingCard(
            item: _items[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listingId: _items[i].id),
            )).then((_) => _fetch(reset: true)),
          );
        },
      ),
    );
  }
}

// ── My Listings Tab ───────────────────────────────────────────────────────────

class _MyListingsTab extends StatefulWidget {
  const _MyListingsTab();
  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  final _service = ListingService();
  List<ListingDetailDto> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getMyListings(status: '');
      if (mounted) setState(() { _items = result.items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _service.updateStatus(id, status);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'marketplace_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const CreateListingScreen(),
        )).then((_) => _fetch()),
        icon: const Icon(Icons.add),
        label: const Text('Post Listing'),
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.sell_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No listings yet'),
                      SizedBox(height: 8),
                      Text('Tap the button below to sell your crops',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return _MyListingCard(
                            item: item,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listingId: item.id),
                            )).then((_) => _fetch()),
                            onMarkSold: () => _updateStatus(item.id, 'Sold'),
                            onRemove:   () => _updateStatus(item.id, 'Removed'),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final ListingSummaryDto item;
  final VoidCallback onTap;
  const _ListingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 68, height: 68,
                child: item.thumbnailUrl != null
                    ? Image.network(item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _cropIcon())
                    : _cropIcon(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.cropName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (item.variety.isNotEmpty)
                  Text(item.variety,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 11, color: Colors.grey),
                  const SizedBox(width: 2),
                  Expanded(child: Text('${item.district}, ${item.state}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Text('${item.quantityValue.toStringAsFixed(0)} ${item.quantityUnit}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            )),
            const SizedBox(width: 8),
            // Price
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\u20b9${item.pricePerUnit.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16, color: AppTheme.secondary)),
              Text('per ${item.quantityUnit}',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              const SizedBox(height: 6),
              Text(_timeAgo(item.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _cropIcon() => Container(
    color: AppTheme.primary.withValues(alpha: 0.1),
    child: const Icon(Icons.grass, color: AppTheme.primary, size: 32),
  );
}

// ── My Listing Card ───────────────────────────────────────────────────────────

class _MyListingCard extends StatelessWidget {
  final ListingDetailDto item;
  final VoidCallback onTap;
  final VoidCallback onMarkSold;
  final VoidCallback onRemove;
  const _MyListingCard({required this.item, required this.onTap,
    required this.onMarkSold, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == 'Active' ? Colors.green
        : item.status == 'Sold' ? Colors.blue : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60, height: 60,
                child: item.imageUrls.isNotEmpty
                    ? Image.network(item.imageUrls.first, fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                          Container(color: AppTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.grass, color: AppTheme.primary)))
                    : Container(color: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.grass, color: AppTheme.primary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(item.cropName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                    child: Text(item.status,
                      style: TextStyle(color: statusColor, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ),
                ]),
                Text('\u20b9${item.pricePerUnit.toStringAsFixed(0)} / ${item.quantityUnit}',
                  style: const TextStyle(color: AppTheme.secondary,
                    fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${item.quantityValue.toStringAsFixed(0)} ${item.quantityUnit} \u00b7 ${item.district}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            )),
            if (item.status == 'Active')
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'sold') onMarkSold();
                  if (v == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'sold', child: Text('Mark as Sold')),
                  const PopupMenuItem(value: 'remove',
                    child: Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
          ]),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return '${diff.inMinutes}m ago';
}
