import 'package:flutter/material.dart';
import '../api/rating_service.dart';
import '../theme/app_theme.dart';

// ── Star row (display only) ────────────────────────────────────────────────────

class StarDisplay extends StatelessWidget {
  final double score;
  final double size;
  const StarDisplay({super.key, required this.score, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < score.floor();
        final half = !filled && i < score;
        return Icon(
          filled ? Icons.star : half ? Icons.star_half : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

// ── Tappable star row (for input) ─────────────────────────────────────────────

class StarInput extends StatefulWidget {
  final int initial;
  final ValueChanged<int> onChanged;
  final double size;
  const StarInput({super.key, this.initial = 0, required this.onChanged, this.size = 32});

  @override
  State<StarInput> createState() => _StarInputState();
}

class _StarInputState extends State<StarInput> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < _selected;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = i + 1);
            widget.onChanged(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}

// ── Rate User Dialog ───────────────────────────────────────────────────────────

Future<bool> showRateUserDialog({
  required BuildContext context,
  required String rateeUserId,
  required String rateeName,
  RatingDto? existing,
}) async {
  int score = existing?.score ?? 0;
  final commentCtrl = TextEditingController(text: existing?.comment ?? '');
  final service = RatingService();
  bool saving = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate $rateeName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (existing != null)
              const Text('Update your review',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarInput(
              initial: score,
              size: 36,
              onChanged: (v) => setS(() => score = v),
            ),
            const SizedBox(height: 6),
            Text(
              score == 0 ? 'Tap to rate'
                : score == 1 ? 'Poor'
                : score == 2 ? 'Fair'
                : score == 3 ? 'Good'
                : score == 4 ? 'Very Good'
                : 'Excellent',
              style: TextStyle(
                color: score == 0 ? Colors.grey : Colors.amber[700],
                fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (score == 0 || saving)
                ? null
                : () async {
                    setS(() => saving = true);
                    try {
                      await service.submitRating(
                        rateeUserId: rateeUserId,
                        score: score,
                        comment: commentCtrl.text.trim().isEmpty
                            ? null
                            : commentCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e')));
                      }
                      setS(() => saving = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

// ── Reviews section widget ─────────────────────────────────────────────────────

class UserReviewsSection extends StatefulWidget {
  final String userId;
  final String userName;
  final bool showRateButton;
  final String? currentUserId; // to check if already rated
  const UserReviewsSection({
    super.key,
    required this.userId,
    required this.userName,
    this.showRateButton = false,
    this.currentUserId,
  });

  @override
  State<UserReviewsSection> createState() => _UserReviewsSectionState();
}

class _UserReviewsSectionState extends State<UserReviewsSection> {
  final _service = RatingService();
  UserRatingSummary? _summary;
  RatingDto? _myRating;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await _service.getUserRatings(widget.userId);
      RatingDto? myRating;
      if (widget.currentUserId != null && widget.currentUserId != widget.userId) {
        myRating = await _service.getMyRatingForUser(widget.userId);
      }
      if (mounted) setState(() { _summary = summary; _myRating = myRating; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRateDialog() async {
    final submitted = await showRateUserDialog(
      context: context,
      rateeUserId: widget.userId,
      rateeName: widget.userName,
      existing: _myRating,
    );
    if (submitted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final s = _summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Text('Reviews',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (widget.showRateButton &&
                widget.currentUserId != null &&
                widget.currentUserId != widget.userId)
              TextButton.icon(
                onPressed: _openRateDialog,
                icon: Icon(
                  _myRating == null ? Icons.rate_review_outlined : Icons.edit_outlined,
                  size: 16),
                label: Text(_myRating == null ? 'Rate' : 'Edit Review'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
          ]),
        ),

        // Summary card
        if (s != null && s.totalCount > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Text(s.averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StarDisplay(score: s.averageScore, size: 20),
                const SizedBox(height: 2),
                Text('${s.totalCount} review${s.totalCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('No reviews yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),

        // Individual reviews
        if (s != null)
          ...s.reviews.map((r) => _ReviewTile(review: r)),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RatingDto review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(
              review.raterName.isNotEmpty ? review.raterName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(review.raterName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  StarDisplay(score: review.score.toDouble(), size: 13),
                ]),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(review.comment!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(review.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
