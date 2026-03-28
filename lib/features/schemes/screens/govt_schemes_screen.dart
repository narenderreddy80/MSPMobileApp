import 'package:flutter/material.dart';

const _kGreen  = Color(0xFF4CAF50);
const _kOrange = Color(0xFFE65100);
const _kAmber  = Color(0xFFFFC107);
const _kBlue   = Color(0xFF1565C0);

class GovtSchemesScreen extends StatelessWidget {
  const GovtSchemesScreen({super.key});

  static const _schemes = [
    _SchemeDetail(
      title: 'Soil Health Card Scheme',
      subtitle: 'Free soil testing and nutrient recommendations for every farmer.',
      description:
          'The Soil Health Card (SHC) scheme provides every farmer a Soil Health Card '
          'once every 2 years. The card carries crop-wise recommendations of nutrients '
          'and fertilisers required for individual farms to help improve productivity. '
          'Visit your nearest Krishi Vigyan Kendra (KVK) or Common Service Centre (CSC) '
          'to get your card.',
      icon: Icons.science,
      color: _kAmber,
      tag: 'Free',
    ),
    _SchemeDetail(
      title: 'PM-KISAN',
      subtitle: 'Income support of ₹6,000/year directly to farmer families.',
      description:
          'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN) provides income support of '
          '₹6,000 per year in three equal instalments of ₹2,000 directly to the bank '
          'accounts of eligible farmer families. Instalment 17 is expected by Apr 2026. '
          'Check your beneficiary status on the PM-KISAN portal.',
      icon: Icons.account_balance,
      color: _kBlue,
      tag: 'Cash Transfer',
    ),
    _SchemeDetail(
      title: 'PMFBY – Crop Insurance',
      subtitle: 'Pradhan Mantri Fasal Bima Yojana – insure your Kharif crop.',
      description:
          'PMFBY offers comprehensive crop insurance at very low premium rates '
          '(2% for Kharif, 1.5% for Rabi crops). It covers losses due to natural '
          'calamities, pests and diseases. Last date for Kharif 2026 registration '
          'is 31 July 2026. Apply at your nearest bank or CSC.',
      icon: Icons.shield,
      color: _kGreen,
      tag: 'Insurance',
    ),
    _SchemeDetail(
      title: 'PM Kisan Mandhan Yojana',
      subtitle: 'Monthly pension of ₹3,000 after age 60 for small farmers.',
      description:
          'Small and marginal farmers aged 18–40 can enrol for a guaranteed pension of '
          '₹3,000/month after reaching 60 years of age. A matching contribution is made '
          'by the Government of India. Enrol at your nearest CSC.',
      icon: Icons.elderly,
      color: _kOrange,
      tag: 'Pension',
    ),
    _SchemeDetail(
      title: 'eNAM – National Agriculture Market',
      subtitle: 'Sell your produce online across mandis at the best price.',
      description:
          'eNAM is a pan-India electronic trading portal that networks existing APMC '
          'mandis to create a unified national market for agricultural commodities. '
          'Farmers can sell their produce online without physically visiting distant '
          'mandis, ensuring better price discovery.',
      icon: Icons.storefront,
      color: _kBlue,
      tag: 'Market',
    ),
    _SchemeDetail(
      title: 'Kisan Credit Card (KCC)',
      subtitle: 'Low-interest credit for crop production and allied activities.',
      description:
          'KCC provides farmers timely access to credit at 4% interest per annum '
          '(after interest subvention) for crop production, post-harvest expenses, '
          'maintenance of farm assets, and allied activities. Apply at any bank branch '
          'or through your cooperative society.',
      icon: Icons.credit_card,
      color: _kGreen,
      tag: 'Credit',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Govt. Schemes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _schemes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _SchemeCard(scheme: _schemes[i]),
      ),
    );
  }
}

class _SchemeCard extends StatefulWidget {
  final _SchemeDetail scheme;
  const _SchemeCard({required this.scheme});

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: s.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, color: s.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(s.tag,
                                  style: TextStyle(
                                      color: s.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(s.subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: s.color.withValues(alpha: 0.2)),
                  const SizedBox(height: 6),
                  Text(s.description,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: s.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Apply / Know More'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SchemeDetail {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String tag;
  const _SchemeDetail({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.tag,
  });
}
