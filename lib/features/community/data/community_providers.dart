import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../data/community_repository.dart';
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