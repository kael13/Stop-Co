import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/community_providers.dart';
import '../domain/community_sort.dart';
import 'guest_gate_dialog.dart';
import 'post_card.dart';
import 'post_composer_screen.dart';

/// The 5th tab in [MainShell]: community feed with sort chips, live-updating
/// post list, shimmer skeleton loader, and a "New post" FAB (auth-gated).
///
/// Guests (anonymous or unverified) can scroll the feed but tapping the FAB
/// or vote/comment surfaces (in Phase A.3) shows [GuestGateDialog].
class CommunityFeedTab extends ConsumerStatefulWidget {
  const CommunityFeedTab({super.key});

  @override
  ConsumerState<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends ConsumerState<CommunityFeedTab> {
  CommunitySort _sort = CommunitySort.relevant;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentCommunityUserProvider);
    final user = userAsync.valueOrNull;
    final canWrite = user != null && user.canWriteCommunity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: false,
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PostComposerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('New Post'),
            )
          : FloatingActionButton.extended(
              onPressed: () => showGuestGateDialog(context),
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Sign in to Post'),
            ),
      body: Column(
        children: [
          _SortChips(
            current: _sort,
            onChanged: (s) => setState(() => _sort = s),
          ),
          Expanded(
            child: _FeedBody(sort: _sort, canWrite: canWrite),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  final CommunitySort current;
  final ValueChanged<CommunitySort> onChanged;
  const _SortChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SegmentedButton<CommunitySort>(
        segments: CommunitySort.values
            .map((s) => ButtonSegment(
                  value: s,
                  label: Text(s.label, style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (set) => onChanged(set.first),
        style: const ButtonStyle(
          visualDensity: VisualDensity(horizontal: -2, vertical: -1),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.05, end: 0, duration: 200.ms);
  }
}

class _FeedBody extends ConsumerWidget {
  final CommunitySort sort;
  final bool canWrite;
  const _FeedBody({required this.sort, required this.canWrite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider(
      CommunitySortArg(sort: sort),
    ));
    return feedAsync.when(
      loading: () => const _FeedSkeleton(),
      error: (e, _) => _FeedError(message: e.toString()),
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyFeed();
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityFeedProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(
              post: posts[index],
              index: index,
              onTap: () {
                // TODO: push PostDetailScreen (Phase A.3)
              },
            ),
          ),
        );
      },
    );
  }
}

class _FeedError extends StatelessWidget {
  final String message;
  const _FeedError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off_rounded,
                size: 48, color: context.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load posts', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message.replaceAll('Exception: ', ''),
              style: AppTypography.secondary.copyWith(color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined,
                size: 56, color: context.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('No posts yet', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Be the first to share something here.',
              style: AppTypography.secondary.copyWith(color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.outlineVariant,
      highlightColor: context.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => const _CardSkeleton(),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.outlineVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ShimmerBox(width: 32, height: 32, radius: 16),
                const SizedBox(width: AppSpacing.sm),
                _ShimmerBox(width: 120, height: 12),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ShimmerBox(width: double.infinity, height: 14),
            const SizedBox(height: AppSpacing.xs),
            _ShimmerBox(width: 240, height: 14),
            const SizedBox(height: AppSpacing.md),
            _ShimmerBox(width: double.infinity, height: 120, radius: 12),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.outlineVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}