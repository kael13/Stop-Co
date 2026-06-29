import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../data/community_repository.dart';
import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';
import '../domain/community_sort.dart';
import '../domain/vote_value.dart';

/// Single shared instance of [CommunityRepository].
///
/// Reads [FirebaseFirestore] + [FirebaseStorage] singletons configured via
/// the existing `Firebase.initializeApp()` call in `main.dart`.
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

/// Current signed-in user, or null if guest (convenience alias for `authStateProvider`).
final currentCommunityUserProvider = StreamProvider<UserSignedIn?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return auth.authStateChanges.map((user) {
    if (user != null) {
      return UserSignedIn(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        isAnonymous: user.isAnonymous,
        emailVerified: user.emailVerified,
      );
    }
    return null;
  });
});

/// Family: live feed stream by sort mode. Pass [CommunitySort] as the arg.
final communityFeedProvider = StreamProvider.family
    .autoDispose<List<CommunityPost>, CommunitySortArg>((ref, arg) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchFeed(sort: arg.sort, limit: arg.limit);
});

/// Wraps [CommunitySort] + optional limit + cursor so the family arg is
/// snapshot-able (Riverpod families require value-equality).
class CommunitySortArg {
  final CommunitySort sort;
  final int limit;
  const CommunitySortArg({required this.sort, this.limit = 20});
  @override
  bool operator ==(Object other) =>
      other is CommunitySortArg && other.sort == sort && other.limit == limit;
  @override
  int get hashCode => Object.hash(sort, limit);
}

/// Live stream for a single post (post detail screen).
final communityPostProvider =
    StreamProvider.family.autoDispose<CommunityPost, String>((ref, id) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchPost(id);
});

/// Async action wrapper for casting/flipping/removing a post vote.
/// Call then `ref.invalidate(communityPostProvider(postId))` to refresh UI.
final votePostActionProvider =
    FutureProvider.family.autoDispose<void, VotePostArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.votePost(args.postId, args.value, args.uid);
});

class VotePostArgs {
  final String postId;
  final VoteValue value;
  final String uid;
  const VotePostArgs(this.postId, this.value, this.uid);
  @override
  bool operator ==(Object other) =>
      other is VotePostArgs &&
      other.postId == postId &&
      other.value == value &&
      other.uid == uid;
  @override
  int get hashCode => Object.hash(postId, value, uid);
}

/// Async action for creating a new post. Returns the new post ID.
/// The caller is responsible for invalidating the feed after this resolves.
final createPostActionProvider =
    FutureProvider.family.autoDispose<String, CreatePostArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.createPost(
    author: args.author,
    description: args.description,
    latitude: args.latitude,
    longitude: args.longitude,
    placeName: args.placeName,
    imageURLs: args.imageURLs,
    imagePaths: args.imagePaths,
    postId: args.postId,
  );
});

class CreatePostArgs {
  final UserSignedIn author;
  final String description;
  final double latitude;
  final double longitude;
  final String? placeName;
  final List<String> imageURLs;
  final List<String> imagePaths;
  final String? postId;
  const CreatePostArgs({
    required this.author,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.imageURLs = const [],
    this.imagePaths = const [],
    this.postId,
  });
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

/// Live stream of flat comments for a post, sorted by score-then-recent.
final watchCommentsProvider = StreamProvider.family
    .autoDispose<List<CommunityComment>, String>((ref, postId) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchComments(postId);
});

/// Async action: add a text comment to a post. Returns comment ID.
/// The caller invalidates [watchCommentsProvider] after this resolves.
final addCommentActionProvider =
    FutureProvider.family.autoDispose<String, AddCommentArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.addComment(
    author: args.author,
    postId: args.postId,
    text: args.text,
  );
});

class AddCommentArgs {
  final UserSignedIn author;
  final String postId;
  final String text;
  const AddCommentArgs({
    required this.author,
    required this.postId,
    required this.text,
  });
  @override
  bool operator ==(Object other) =>
      other is AddCommentArgs &&
      other.postId == postId &&
      other.text == text &&
      other.author.uid == author.uid;
  @override
  int get hashCode => Object.hash(postId, text, author.uid);
}

/// Async action: update a comment's text (within 15-min edit lock).
final updateCommentActionProvider =
    FutureProvider.family.autoDispose<void, UpdateCommentArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.updateComment(args.comment, text: args.text);
});

class UpdateCommentArgs {
  final CommunityComment comment;
  final String text;
  const UpdateCommentArgs({required this.comment, required this.text});
  @override
  bool operator ==(Object other) =>
      other is UpdateCommentArgs &&
      other.comment.id == comment.id &&
      other.text == text;
  @override
  int get hashCode => Object.hash(comment.id, text);
}

/// Async action: delete a comment (author-only, enforced by Firestore rules).
final deleteCommentActionProvider =
    FutureProvider.family.autoDispose<void, CommunityComment>((ref, comment) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.deleteComment(comment);
});

// ---------------------------------------------------------------------------
// Comment votes
// ---------------------------------------------------------------------------

/// Async action: cast/flip/remove a comment vote.
/// Invalidate [myCommentVotesProvider] after this resolves.
final voteCommentActionProvider =
    FutureProvider.family.autoDispose<void, VoteCommentArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.voteComment(args.commentId, args.value, args.uid);
});

class VoteCommentArgs {
  final String commentId;
  final VoteValue value;
  final String uid;
  const VoteCommentArgs(this.commentId, this.value, this.uid);
  @override
  bool operator ==(Object other) =>
      other is VoteCommentArgs &&
      other.commentId == commentId &&
      other.value == value &&
      other.uid == uid;
  @override
  int get hashCode => Object.hash(commentId, value, uid);
}

// ---------------------------------------------------------------------------
// Post edit / delete
// ---------------------------------------------------------------------------

/// Async action: edit a post's description (within 15-min edit lock).
final updatePostActionProvider =
    FutureProvider.family.autoDispose<void, UpdatePostArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.updatePost(args.post, description: args.description);
});

class UpdatePostArgs {
  final CommunityPost post;
  final String description;
  const UpdatePostArgs({required this.post, required this.description});
  @override
  bool operator ==(Object other) =>
      other is UpdatePostArgs &&
      other.post.id == post.id &&
      other.description == description;
  @override
  int get hashCode => Object.hash(post.id, description);
}

/// Async action: delete a post (author-only, enforced by Firestore rules).
final deletePostActionProvider =
    FutureProvider.family.autoDispose<void, CommunityPost>((ref, post) async {
  final repo = ref.watch(communityRepositoryProvider);
  await repo.deletePost(post);
});

// ---------------------------------------------------------------------------
// My-votes state (one-shot fetch, invalidate on each vote)
// ---------------------------------------------------------------------------

/// One-shot fetch of the current user's votes on a set of post IDs.
/// Returns a map of `postId → VoteValue`. Invalidate after each vote to
/// refresh the highlight state.
final myPostVotesProvider = FutureProvider.family
    .autoDispose<Map<String, VoteValue>, MyVotesArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.myVotesForPosts(args.ids, args.uid);
});

/// One-shot fetch of the current user's votes on a set of comment IDs.
final myCommentVotesProvider = FutureProvider.family
    .autoDispose<Map<String, VoteValue>, MyVotesArgs>((ref, args) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.myVotesForComments(args.ids, args.uid);
});

class MyVotesArgs {
  final List<String> ids;
  final String uid;
  const MyVotesArgs({required this.ids, required this.uid});
  @override
  bool operator ==(Object other) =>
      other is MyVotesArgs && other.uid == uid && _listEquals(other.ids, ids);
  @override
  int get hashCode => Object.hash(uid, Object.hashAll(ids));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}