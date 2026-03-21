import 'package:flutter/material.dart';
import '../../../core/api/mandi_service.dart';
import '../../../core/theme/app_theme.dart';

class MandiHistoryScreen extends StatefulWidget {
  final String commodity;
  final String market;
  final String? variety;
  final String state;

  const MandiHistoryScreen({
    super.key,
    required this.commodity,
    required this.market,
    required this.state,
    this.variety,
  });

  @override
  State<MandiHistoryScreen> createState() => _MandiHistoryScreenState();
}

class _MandiHistoryScreenState extends State<MandiHistoryScreen> {
  final _service = MandiService();
  List<MandiHistoryDto> _history = [];
  bool _loading = true;
  String? _error;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getHistory(
        commodity: widget.commodity,
        market: widget.market,
        variety: widget.variety,
        days: _days,
      );
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.commodity,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(widget.market,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Info banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${widget.state}  ·  ${widget.market}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                ),
                // Days filter
                DropdownButton<int>(
                  value: _days,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 7,   child: Text('7 days',  style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 30,  child: Text('30 days', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 90,  child: Text('90 days', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 365, child: Text('1 year',  style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    setState(() => _days = v!);
                    _fetch();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load history'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No history yet', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'History is built automatically each day when prices are fetched. '
                'Check back tomorrow for price trends.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // Summary stats
    final modals = _history.map((h) => h.modalPrice).toList();
    final avgPrice = modals.reduce((a, b) => a + b) / modals.length;
    final maxModal = modals.reduce((a, b) => a > b ? a : b);
    final minModal = modals.reduce((a, b) => a < b ? a : b);
    final latest = _history.last.modalPrice;
    final prev = _history.length > 1 ? _history[_history.length - 2].modalPrice : latest;
    final change = prev != 0 ? ((latest - prev) / prev * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Summary card
          _SummaryCard(
            latest: latest,
            avg: avgPrice,
            high: maxModal,
            low: minModal,
            change: change.toDouble(),
          ),
          const SizedBox(height: 14),

          // Mini bar chart
          if (_history.length > 1) ...[
            _PriceBarChart(history: _history),
            const SizedBox(height: 14),
          ],

          // History list
          Text('Price Records (${_history.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._history.reversed.map((h) => _HistoryRow(entry: h)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double latest;
  final double avg;
  final double high;
  final double low;
  final double change;

  const _SummaryCard({
    required this.latest,
    required this.avg,
    required this.high,
    required this.low,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('₹${latest.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 32,
                    fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isUp ? Colors.green : Colors.red),
                      Text('${change.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Latest modal price (₹/quintal)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCol('Avg', '₹${avg.toStringAsFixed(0)}', Colors.blue),
                _StatCol('High', '₹${high.toStringAsFixed(0)}', Colors.green),
                _StatCol('Low', '₹${low.toStringAsFixed(0)}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold,
        fontSize: 16, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

class _PriceBarChart extends StatelessWidget {
  final List<MandiHistoryDto> history;
  const _PriceBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final prices = history.map((h) => h.modalPrice).toList();
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final range = maxP - minP;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modal Price Trend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: history.map((h) {
                  final heightFrac = range > 0
                    ? (h.modalPrice - minP) / range
                    : 1.0;
                  final barHeight = 16 + (64 * heightFrac);
                  final isLast = h == history.last;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message: '${h.arrivalDate}\n₹${h.modalPrice.toStringAsFixed(0)}',
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isLast
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(history.first.arrivalDate,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                Text(history.last.arrivalDate,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MandiHistoryDto entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(entry.arrivalDate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            _PriceChip('Min', entry.minPrice, Colors.red.shade300),
            const SizedBox(width: 6),
            _PriceChip('Modal', entry.modalPrice, AppTheme.primary),
            const SizedBox(width: 6),
            _PriceChip('Max', entry.maxPrice, Colors.green.shade600),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  const _PriceChip(this.label, this.price, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('₹${price.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold,
            fontSize: 12, color: color)),
        Text(label,
          style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }
}
