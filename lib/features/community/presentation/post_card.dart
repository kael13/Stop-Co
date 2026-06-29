import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/models/community_post.dart';
import '../domain/vote_value.dart';
import 'coordinate_chip.dart';

/// A single post card rendered in the community feed.
///
/// Displays: author avatar/name, timestamp, description, image grid (up to 3),
/// coordinate chip, interactive vote arrows + comment count. Tap navigates to
/// [PostDetailScreen].
class PostCard extends StatelessWidget {
  final CommunityPost post;
  final int index;
  final VoidCallback? onTap;
  final VoteValue myVote;
  final bool canVote;
  final ValueChanged<VoteValue>? onVote;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
    this.onTap,
    this.myVote = VoteValue.none,
    this.canVote = false,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorRow(post: post),
                const SizedBox(height: AppSpacing.xs),
                if (post.description.isNotEmpty) ...[
                  Text(
                    post.description,
                    style: AppTypography.secondary,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (post.imageURLs.isNotEmpty) ...[
                  _ImageGrid(urls: post.imageURLs),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (post.latitude != 0 || post.longitude != 0)
                  CoordinateChip(
                    latitude: post.latitude,
                    longitude: post.longitude,
                    placeName: post.placeName,
                    compact: true,
                  ),
                const SizedBox(height: AppSpacing.xs),
                _FooterRow(
                  post: post,
                  myVote: myVote,
                  onVote: onVote,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (index * 60).ms,
          duration: 280.ms,
        )
        .slideY(begin: 0.08, end: 0, duration: 280.ms);
  }
}

class _AuthorRow extends StatelessWidget {
  final CommunityPost post;
  const _AuthorRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: context.primary.withValues(alpha: 0.15),
          backgroundImage:
              post.authorPhotoURL != null ? NetworkImage(post.authorPhotoURL!) : null,
          child: post.authorPhotoURL == null
              ? Text(
                  (post.authorName.isNotEmpty ? post.authorName : 'A')[0]
                      .toUpperCase(),
                  style: TextStyle(color: context.primary, fontSize: 11),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: AppTypography.secondary.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: AppTypography.secondary.copyWith(
                  color: context.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (post.isEdited)
          Text(
            '(edited)',
            style: AppTypography.secondary.copyWith(
              color: context.textTertiary,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    final count = urls.length;
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Image.network(
          urls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 160,
          errorBuilder: (_, _, _) => Container(
            height: 160,
            color: context.outlineVariant,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    }
    return Row(
        children: List.generate(count, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < count - 1 ? AppSpacing.xs : 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: context.outlineVariant,
                      child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 20)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
  }
}

class _FooterRow extends StatelessWidget {
  final CommunityPost post;
  final VoteValue myVote;
  final ValueChanged<VoteValue>? onVote;
  const _FooterRow({required this.post, required this.myVote, this.onVote});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VoteArrow(
          icon: Icons.arrow_upward_rounded,
          isActive: myVote == VoteValue.up,
          color: myVote == VoteValue.up ? Colors.green : context.textTertiary,
          onTap: onVote == null
              ? null
              : () => onVote!(
                    myVote == VoteValue.up ? VoteValue.none : VoteValue.up,
                  ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '${post.score}',
          style: AppTypography.secondary.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        _VoteArrow(
          icon: Icons.arrow_downward_rounded,
          isActive: myVote == VoteValue.down,
          color: myVote == VoteValue.down ? Colors.red : context.textTertiary,
          onTap: onVote == null
              ? null
              : () => onVote!(
                    myVote == VoteValue.down ? VoteValue.none : VoteValue.down,
                  ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.chat_bubble_outline_rounded,
            size: 16, color: context.textTertiary),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '${post.commentCount}',
          style: AppTypography.secondary.copyWith(
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VoteArrow extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;
  const _VoteArrow({
    required this.icon,
    required this.isActive,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isActive ? 1.2 : 1.0,
        duration: 150.ms,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}