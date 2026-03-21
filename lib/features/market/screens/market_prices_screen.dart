import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  String _selectedState = 'Telangana';
  String _selectedCommodity = 'All';
  String _searchQuery = '';

  final _states = ['Telangana', 'Andhra Pradesh', 'Karnataka', 'Maharashtra', 'Punjab'];
  final _commodities = ['All', 'Paddy', 'Cotton', 'Maize', 'Soybean', 'Wheat'];

  final _prices = [
    _PriceData('Paddy (Common)', 'Hyderabad', 2183, 2250, 2.0, 'Telangana'),
    _PriceData('Paddy (Grade A)', 'Warangal', 2203, 2280, 3.5, 'Telangana'),
    _PriceData('Cotton (Long Staple)', 'Adilabad', 6800, 7100, -2.0, 'Telangana'),
    _PriceData('Maize', 'Nizamabad', 1600, 1780, 1.2, 'Telangana'),
    _PriceData('Soybean', 'Karimnagar', 3900, 4200, 0.5, 'Telangana'),
    _PriceData('Red Chilli', 'Guntur', 8500, 9200, 4.0, 'Andhra Pradesh'),
    _PriceData('Groundnut', 'Kurnool', 5200, 5800, -1.0, 'Andhra Pradesh'),
    _PriceData('Wheat', 'Amritsar', 2015, 2100, 0.8, 'Punjab'),
    _PriceData('Sugarcane', 'Pune', 2850, 3000, 1.5, 'Maharashtra'),
    _PriceData('Onion', 'Nashik', 1200, 1600, 6.0, 'Maharashtra'),
  ];

  List<_PriceData> get _filtered {
    return _prices.where((p) {
      final matchState = p.state == _selectedState;
      final matchCommodity = _selectedCommodity == 'All' ||
        p.commodity.toLowerCase().contains(_selectedCommodity.toLowerCase());
      final matchSearch = _searchQuery.isEmpty ||
        p.commodity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.market.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchState && matchCommodity && matchSearch;
    }).toList();
  }

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search commodity or market...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _DropdownFilter(
                      label: 'State',
                      value: _selectedState,
                      items: _states,
                      onChanged: (v) => setState(() => _selectedState = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DropdownFilter(
                      label: 'Commodity',
                      value: _selectedCommodity,
                      items: _commodities,
                      onChanged: (v) => setState(() => _selectedCommodity = v!),
                    )),
                  ],
                ),
              ],
            ),
          ),
          // Summary banner
          Container(
            color: AppTheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('Prices in ₹/quintal · Updated: ${_today()}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                const Spacer(),
                Text('${_filtered.length} results',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Price list
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _PriceCard(data: _filtered[i]),
                ),
          ),
        ],
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

class _PriceCard extends StatelessWidget {
  final _PriceData data;
  const _PriceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isUp = data.change >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_basket, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.commodity,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(data.market,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${data.modalPrice}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isUp ? Colors.green : Colors.red),
                    Text('${data.change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('Min: ₹${data.minPrice}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceData {
  final String commodity;
  final String market;
  final int minPrice;
  final int modalPrice;
  final double change;
  final String state;
  const _PriceData(this.commodity, this.market, this.minPrice, this.modalPrice,
      this.change, this.state);
}
