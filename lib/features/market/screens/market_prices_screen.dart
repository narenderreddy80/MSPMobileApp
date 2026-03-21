import 'package:flutter/material.dart';
import '../../../core/api/mandi_service.dart';
import '../../../core/theme/app_theme.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final _service = MandiService();

  String _selectedState = '';
  String _selectedCommodity = '';
  String _searchQuery = '';

  final _states = [
    '', 'Andhra Pradesh', 'Karnataka', 'Kerala', 'Maharashtra',
    'Madhya Pradesh', 'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana',
    'Uttar Pradesh', 'West Bengal',
  ];

  List<MandiPriceDto> _prices = [];
  bool _loading = false;
  String? _error;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getPrices(
        state: _selectedState.isEmpty ? null : _selectedState,
        commodity: _selectedCommodity.isEmpty ? null : _selectedCommodity,
        limit: 100,
      );
      if (mounted) setState(() { _prices = data; _hasLoaded = true; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MandiPriceDto> get _filtered => _searchQuery.isEmpty
    ? _prices
    : _prices.where((p) =>
        p.commodity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.market.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.district.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mandi Prices')),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search commodity, market, district...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _StateDropdown(
                      value: _selectedState,
                      states: _states,
                      onChanged: (v) {
                        setState(() => _selectedState = v ?? '');
                        _fetch();
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _CommodityField(
                      value: _selectedCommodity,
                      onSubmitted: (v) {
                        setState(() => _selectedCommodity = v);
                        _fetch();
                      },
                    )),
                  ],
                ),
              ],
            ),
          ),
          // Status bar
          Container(
            color: AppTheme.primary.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: AppTheme.primary),
                const SizedBox(width: 5),
                const Text('Prices in ₹/quintal · Source: data.gov.in',
                  style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                const Spacer(),
                if (_hasLoaded)
                  Text('${_filtered.length} results',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary,
                      fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Could not fetch prices', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No results found'),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ]
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _PriceCard(data: _filtered[i]),
      ),
    );
  }
}

class _StateDropdown extends StatelessWidget {
  final String value;
  final List<String> states;
  final void Function(String?) onChanged;
  const _StateDropdown({required this.value, required this.states, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: states.map((s) => DropdownMenuItem(
        value: s,
        child: Text(s.isEmpty ? 'All States' : s, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

class _CommodityField extends StatefulWidget {
  final String value;
  final void Function(String) onSubmitted;
  const _CommodityField({required this.value, required this.onSubmitted});

  @override
  State<_CommodityField> createState() => _CommodityFieldState();
}

class _CommodityFieldState extends State<_CommodityField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onSubmitted: widget.onSubmitted,
      decoration: const InputDecoration(
        labelText: 'Commodity',
        hintText: 'e.g. Paddy',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        suffixIcon: Icon(Icons.search, size: 16),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final MandiPriceDto data;
  const _PriceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_basket, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.commodity,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (data.variety.isNotEmpty)
                    Text(data.variety,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  Row(children: [
                    const Icon(Icons.location_on, size: 11, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text('${data.market}, ${data.district}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${data.modalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                    color: AppTheme.primary)),
                Text('modal',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                Text('₹${data.minPrice.toStringAsFixed(0)}–${data.maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                if (data.arrivalDate.isNotEmpty)
                  Text(data.arrivalDate,
                    style: TextStyle(color: Colors.grey[400], fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
