import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/community_providers.dart';
import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';
import '../domain/vote_value.dart';
import 'coordinate_chip.dart';
import 'guest_gate_dialog.dart';

/// Full-screen view of a single post with live-updating header, interactive
/// vote bar, and a flat comments list sorted by score-then-recent.
///
/// Write surfaces (vote, comment) are auth-gated via [showGuestGateDialog] for
/// guests or unverified users. The post author sees Edit / Delete actions in
/// the app-bar overflow menu (within the 15-min edit lock for Edit).
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _canWrite() {
    final user = ref.read(currentCommunityUserProvider).valueOrNull;
    return user != null && user.canWriteCommunity;
  }

  Future<void> _votePost(VoteValue value) async {
    if (!_canWrite()) {
      if (mounted) showGuestGateDialog(context);
      return;
    }
    final user = ref.read(currentCommunityUserProvider).valueOrNull!;
    await ref.read(votePostActionProvider(
      VotePostArgs(widget.postId, value, user.uid),
    ).future);
    ref.invalidate(myPostVotesProvider);
  }

  Future<void> _voteComment(CommunityComment comment, VoteValue value) async {
    if (!_canWrite()) {
      if (mounted) showGuestGateDialog(context);
      return;
    }
    final user = ref.read(currentCommunityUserProvider).valueOrNull!;
    await ref.read(voteCommentActionProvider(
      VoteCommentArgs(comment.id, value, user.uid),
    ).future);
    ref.invalidate(myCommentVotesProvider);
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (!_canWrite()) {
      if (mounted) showGuestGateDialog(context);
      return;
    }
    final user = ref.read(currentCommunityUserProvider).valueOrNull!;
    setState(() => _isSendingComment = true);
    try {
      await ref.read(addCommentActionProvider(
        AddCommentArgs(author: user, postId: widget.postId, text: text),
      ).future);
      _commentController.clear();
      ref.invalidate(watchCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to comment: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deletePostActionProvider(post).future);
    ref.invalidate(communityFeedProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editPost(CommunityPost post) async {
    if (!post.canEdit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit window has expired (15 min).'),
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final controller = TextEditingController(text: post.description);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == post.description) return;
    try {
      await ref.read(updatePostActionProvider(
        UpdatePostArgs(post: post, description: result),
      ).future);
      ref.invalidate(communityPostProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _editComment(CommunityComment comment) async {
    if (!comment.canEdit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit window has expired (15 min).'),
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final controller = TextEditingController(text: comment.text ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await ref.read(updateCommentActionProvider(
        UpdateCommentArgs(comment: comment, text: result),
      ).future);
      ref.invalidate(watchCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(deleteCommentActionProvider(comment).future);
      ref.invalidate(watchCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final user = ref.watch(currentCommunityUserProvider).valueOrNull;
    final commentsAsync = ref.watch(watchCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: context.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('Couldn\'t load post', style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: AppTypography.secondary
                      .copyWith(color: context.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (post) {
          if (post.moderationStatus.name == 'removed') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_off_rounded, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text('Post removed', style: AppTypography.title),
                  ],
                ),
              ),
            );
          }
          final isAuthor = user?.uid == post.authorUid;
          final commentIds = commentsAsync.valueOrNull
              ?.map((c) => c.id)
              .toList() ?? const [];
          final postVotesAsync = ref.watch(myPostVotesProvider(
            MyVotesArgs(ids: [post.id], uid: user?.uid ?? ''),
          ));
          final commentVotesAsync = user != null
              ? ref.watch(myCommentVotesProvider(
                  MyVotesArgs(ids: commentIds, uid: user.uid),
                ))
              : null;

          final myPostVote = postVotesAsync.valueOrNull?[post.id] ??
              VoteValue.none;
          final myCommentVotes = commentVotesAsync?.valueOrNull ?? const {};

          return ListView(
            children: [
              _PostHeader(
                post: post,
                isAuthor: isAuthor,
                myVote: myPostVote,
                onVote: _votePost,
                onEdit: () => _editPost(post),
                onDelete: () => _deletePost(post),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                child: Text('Comments', style: AppTypography.sectionHeader.copyWith(fontSize: 16)),
              ),
              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('Failed to load comments: $e',
                      style: AppTypography.secondary),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No comments yet. Be the first!',
                          style: AppTypography.secondary
                              .copyWith(color: context.textTertiary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: comments.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      final c = entry.value;
                      return _CommentTile(
                        comment: c,
                        isFirst: isFirst,
                        myVote: myCommentVotes[c.id] ?? VoteValue.none,
                        canModify: user?.uid == c.authorUid,
                        onVote: (v) => _voteComment(c, v),
                        onEdit: () => _editComment(c),
                        onDelete: () => _deleteComment(c),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
      bottomNavigationBar: _CommentComposer(
        controller: _commentController,
        onSend: _sendComment,
        disabled: _isSendingComment,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post header
// ---------------------------------------------------------------------------

class _PostHeader extends StatelessWidget {
  final CommunityPost post;
  final bool isAuthor;
  final VoteValue myVote;
  final ValueChanged<VoteValue> onVote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PostHeader({
    required this.post,
    required this.isAuthor,
    required this.myVote,
    required this.onVote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: context.primary.withValues(alpha: 0.15),
                backgroundImage: post.authorPhotoURL != null
                    ? NetworkImage(post.authorPhotoURL!)
                    : null,
                child: post.authorPhotoURL == null
                    ? Text(
                        (post.authorName.isNotEmpty
                                ? post.authorName
                                : 'A')[0].toUpperCase(),
                        style: TextStyle(color: context.primary, fontSize: 11),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: AppTypography.secondary
                            .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      _timeAgo(post.createdAt),
                      style: AppTypography.secondary
                          .copyWith(color: context.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (post.isEdited)
                Text('(edited)',
                    style: AppTypography.secondary
                        .copyWith(color: context.textTertiary, fontSize: 10)),
              if (isAuthor)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (post.canEdit)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(post.description, style: AppTypography.secondary),
          if (post.imageURLs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _ImageGrid(urls: post.imageURLs),
          ],
          if (post.latitude != 0 || post.longitude != 0) ...[
            const SizedBox(height: AppSpacing.xs),
            CoordinateChip(
              latitude: post.latitude,
              longitude: post.longitude,
              placeName: post.placeName,
              compact: true,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _VoteBar(
            score: post.score,
            myVote: myVote,
            onVote: onVote,
            commentCount: post.commentCount,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, end: 0, duration: 250.ms);
  }
}

// ---------------------------------------------------------------------------
// Vote bar (shared by post header and comment tiles)
// ---------------------------------------------------------------------------

class _VoteBar extends StatelessWidget {
  final int score;
  final VoteValue myVote;
  final ValueChanged<VoteValue> onVote;
  final int? commentCount;
  const _VoteBar({
    required this.score,
    required this.myVote,
    required this.onVote,
    this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VoteArrow(
          icon: Icons.arrow_upward_rounded,
          isActive: myVote == VoteValue.up,
          color: myVote == VoteValue.up ? Colors.green : context.textTertiary,
          onTap: () => onVote(
            myVote == VoteValue.up ? VoteValue.none : VoteValue.up,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$score',
          style: AppTypography.secondary.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: AppSpacing.xxs),
        _VoteArrow(
          icon: Icons.arrow_downward_rounded,
          isActive: myVote == VoteValue.down,
          color: myVote == VoteValue.down ? Colors.red : context.textTertiary,
          onTap: () => onVote(
            myVote == VoteValue.down ? VoteValue.none : VoteValue.down,
          ),
        ),
        if (commentCount != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chat_bubble_outline_rounded,
              size: 16, color: context.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          Text('$commentCount',
              style: AppTypography.secondary
                  .copyWith(color: context.textSecondary, fontSize: 13)),
        ],
      ],
    );
  }
}

class _VoteArrow extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _VoteArrow({
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isActive ? 1.2 : 1.0,
        duration: 150.ms,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment tile
// ---------------------------------------------------------------------------

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final bool isFirst;
  final VoteValue myVote;
  final bool canModify;
  final ValueChanged<VoteValue> onVote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CommentTile({
    required this.comment,
    this.isFirst = false,
    required this.myVote,
    required this.canModify,
    required this.onVote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = context.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(width: 2, color: lineColor),
                    ),
                  ),
                  if (!isFirst)
                    Positioned(
                      left: 0,
                      top: 14,
                      child: Container(
                        width: 10,
                        height: 2,
                        color: lineColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: context.primary.withValues(alpha: 0.15),
                          backgroundImage: comment.authorPhotoURL != null
                              ? NetworkImage(comment.authorPhotoURL!)
                              : null,
                          child: comment.authorPhotoURL == null
                              ? Text(
                                  (comment.authorName.isNotEmpty
                                          ? comment.authorName
                                          : 'A')[0].toUpperCase(),
                                  style: TextStyle(color: context.primary, fontSize: 9),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(comment.authorName,
                            style: AppTypography.secondary
                                .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(_timeAgo(comment.createdAt),
                            style: AppTypography.secondary
                                .copyWith(color: context.textTertiary, fontSize: 10)),
                        if (comment.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text('(edited)',
                                style: AppTypography.secondary
                                    .copyWith(color: context.textTertiary, fontSize: 9)),
                          ),
                        const Spacer(),
                        if (canModify)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz_rounded, size: 14),
                            onSelected: (v) {
                              if (v == 'edit') onEdit();
                              if (v == 'delete') onDelete();
                            },
                            itemBuilder: (_) => [
                              if (comment.canEdit)
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (comment.text != null && comment.text!.isNotEmpty)
                      Text(comment.text!, style: AppTypography.secondary),
                    if (comment.imageURL != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Image.network(
                          comment.imageURL!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: context.outlineVariant,
                            child: const Center(
                                child: Icon(Icons.broken_image_outlined, size: 20)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _VoteArrow(
                          icon: Icons.arrow_upward_rounded,
                          isActive: myVote == VoteValue.up,
                          color: myVote == VoteValue.up
                              ? Colors.green
                              : context.textTertiary,
                          onTap: () => onVote(
                            myVote == VoteValue.up ? VoteValue.none : VoteValue.up,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text('${comment.score}',
                            style: AppTypography.secondary.copyWith(fontSize: 11)),
                        const SizedBox(width: AppSpacing.xxs),
                        _VoteArrow(
                          icon: Icons.arrow_downward_rounded,
                          isActive: myVote == VoteValue.down,
                          color: myVote == VoteValue.down
                              ? Colors.red
                              : context.textTertiary,
                          onTap: () => onVote(
                            myVote == VoteValue.down
                                ? VoteValue.none
                                : VoteValue.down,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment composer
// ---------------------------------------------------------------------------

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool disabled;
  const _CommentComposer({
    required this.controller,
    required this.onSend,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(
            top: BorderSide(color: context.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 1,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: BorderSide(color: context.outlineVariant),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            IconButton.filled(
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
              ),
              onPressed: disabled ? null : onSend,
              icon: disabled
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared image grid
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Time-ago helper (duplicated from post_card.dart to keep this file standalone)
// ---------------------------------------------------------------------------

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}