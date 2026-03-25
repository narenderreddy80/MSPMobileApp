import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';

  final _categories = ['All', 'Disease', 'Irrigation', 'Fertilizer', 'Market', 'General'];

  final _posts = [
    _Post(
      author: 'Ramaiah K.',
      avatar: 'R',
      category: 'Disease',
      title: 'Yellow leaves on paddy — fungal or deficiency?',
      body: 'My paddy crop has started showing yellow patches on lower leaves for the past 2 weeks. Applied urea but no improvement. Any suggestions?',
      likes: 24,
      replies: 8,
      time: '2h ago',
      tags: ['paddy', 'yellowing', 'kharif'],
    ),
    _Post(
      author: 'Suresh P.',
      avatar: 'S',
      category: 'Market',
      title: 'Cotton prices in Adilabad are dropping',
      body: 'Mandi rates for cotton fell to ₹6800 this week. Holding stock or selling now? Need advice from experienced farmers.',
      likes: 15,
      replies: 12,
      time: '4h ago',
      tags: ['cotton', 'mandi', 'price'],
    ),
    _Post(
      author: 'Dr. Meena L.',
      avatar: 'M',
      category: 'Fertilizer',
      title: 'Biofertilizer vs Chemical — my 3-year comparison',
      body: 'I have been comparing Rhizobium + PSB biofertilizers against conventional DAP/Urea for soybean over 3 seasons. Sharing detailed results here.',
      likes: 67,
      replies: 31,
      time: '1d ago',
      tags: ['biofertilizer', 'soybean', 'research'],
      isPinned: true,
    ),
    _Post(
      author: 'Venkat R.',
      avatar: 'V',
      category: 'Irrigation',
      title: 'Drip irrigation setup for 5 acres — cost breakdown',
      body: 'Finally installed drip irrigation on my chilli farm. Total cost, subsidy details and what I wish I knew before starting.',
      likes: 45,
      replies: 19,
      time: '2d ago',
      tags: ['drip', 'chilli', 'irrigation'],
    ),
    _Post(
      author: 'Anjali T.',
      avatar: 'A',
      category: 'General',
      title: 'PM-KISAN next installment — when to expect?',
      body: 'Noticed the portal updated but amount not credited yet. Anyone else facing the same? Which district is this?',
      likes: 38,
      replies: 25,
      time: '3d ago',
      tags: ['pm-kisan', 'scheme', 'subsidy'],
    ),
  ];

  List<_Post> get _filtered => _selectedCategory == 'All'
    ? _posts
    : _posts.where((p) => p.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Post',
            onPressed: () => _showNewPostDialog(context),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Category chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: _selectedCategory == c ? AppTheme.primary : Colors.grey[700],
                      fontWeight: _selectedCategory == c ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _PostCard(post: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPostDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NewPostSheet(),
    );
  }
}

class _PostCard extends StatefulWidget {
  final _Post post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Text(post.avatar,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(post.author,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (post.isPinned) ...const [
                          SizedBox(width: 6),
                          Icon(Icons.push_pin, size: 12, color: AppTheme.primary),
                        ],
                      ]),
                      Text(post.time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                _CategoryBadge(post.category),
              ],
            ),
            const SizedBox(height: 10),
            // Title & body
            Text(post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(post.body,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            // Tags
            Wrap(
              spacing: 6,
              children: post.tags.map((t) => Chip(
                label: Text('#$t', style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.07),
                labelStyle: const TextStyle(color: AppTheme.primary),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 8),
            // Actions
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Row(children: [
                    Icon(_liked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _liked ? Colors.red : Colors.grey),
                    const SizedBox(width: 4),
                    Text('${post.likes + (_liked ? 1 : 0)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]),
                ),
                const SizedBox(width: 20),
                Row(children: [
                  const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.replies}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(' replies',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  Color get _color {
    switch (category) {
      case 'Disease': return Colors.red;
      case 'Market': return Colors.blue;
      case 'Fertilizer': return Colors.purple;
      case 'Irrigation': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(category,
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  const _NewPostSheet();

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'General';

  final _cats = ['Disease', 'Irrigation', 'Fertilizer', 'Market', 'General'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Post', style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Your question or story',
              border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.send),
              label: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Post {
  final String author;
  final String avatar;
  final String category;
  final String title;
  final String body;
  final int likes;
  final int replies;
  final String time;
  final List<String> tags;
  final bool isPinned;
  const _Post({
    required this.author,
    required this.avatar,
    required this.category,
    required this.title,
    required this.body,
    required this.likes,
    required this.replies,
    required this.time,
    required this.tags,
    this.isPinned = false,
  });
}
