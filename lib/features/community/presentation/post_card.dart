import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/models/community_post.dart';
import 'coordinate_chip.dart';

/// A single post card rendered in the community feed.
///
/// Displays: author avatar/name, timestamp, description, image grid (up to 3),
/// coordinate chip, vote count + comment count. Tap navigates to post detail
/// (Phase A.3).
class PostCard extends StatelessWidget {
  final CommunityPost post;
  final int index;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorRow(post: post),
                const SizedBox(height: AppSpacing.sm),
                if (post.description.isNotEmpty) ...[
                  Text(
                    post.description,
                    style: AppTypography.body,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (post.imageURLs.isNotEmpty) ...[
                  _ImageGrid(urls: post.imageURLs),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (post.latitude != 0 || post.longitude != 0)
                  CoordinateChip(
                    latitude: post.latitude,
                    longitude: post.longitude,
                    placeName: post.placeName,
                  ),
                const SizedBox(height: AppSpacing.sm),
                _FooterRow(post: post),
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
          radius: 16,
          backgroundColor: context.primary.withValues(alpha: 0.15),
          backgroundImage:
              post.authorPhotoURL != null ? NetworkImage(post.authorPhotoURL!) : null,
          child: post.authorPhotoURL == null
              ? Text(
                  (post.authorName.isNotEmpty ? post.authorName : 'A')[0]
                      .toUpperCase(),
                  style: TextStyle(color: context.primary, fontSize: 13),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
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
          height: 200,
          errorBuilder: (_, _, _) => Container(
            height: 200,
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
  const _FooterRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.arrow_upward_rounded, size: 18, color: context.textTertiary),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '${post.score}',
          style: AppTypography.secondary.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Icon(Icons.arrow_downward_rounded,
            size: 18, color: context.textTertiary),
        const SizedBox(width: AppSpacing.lg),
        Icon(Icons.chat_bubble_outline_rounded,
            size: 18, color: context.textTertiary),
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

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}