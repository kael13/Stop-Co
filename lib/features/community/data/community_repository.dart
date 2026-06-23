import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/community_sort.dart';
import '../domain/moderation_status.dart';
import '../domain/vote_value.dart';
import 'models/community_comment.dart';
import 'models/community_post.dart';

/// Edit lock window for posts and comments.
const _editLockWindow = Duration(minutes: 15);

/// Max images per post (comments are limited to 1).
const maxPostImages = 3;

/// HN-style hot ranking: `log10(score + 1) + createdAtMs / 45000`.
/// Recomputed whenever a post's score changes so the "Relevant" sort stays fresh.
double _hotScore(int score, DateTime createdAt) {
  final ageSeconds = createdAt.millisecondsSinceEpoch / 1000;
  return log(max(score, 0) + 1) / ln10 + (ageSeconds / 45000);
}

/// Data layer for the Community feature.
///
/// Talks directly to Firestore + Storage; all write operations that touch
/// denormalized counters (`upvoteCount`, `downvoteCount`, `score`, `hot`,
/// `commentCount`) run inside `db.runTransaction(...)` so the counters stay
/// consistent even under concurrent votes.
///
/// Collections:
///   posts/{postId}                      votes/posts/{postId}/votes/{uid}
///   comments/{commentId}               votes/comments/{commentId}/votes/{uid}
///   users/{uid}                         reports/{reportId}
class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get _comments =>
      _db.collection('comments');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// Lazy-create the user profile doc on first community interaction.
  /// Safe to call on every action — it's a no-op if the doc already exists.
  Future<void> ensureUserExists(UserSignedIn user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Anonymous',
      'email': user.email,
      'photoURL': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'postCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Feed
  // ---------------------------------------------------------------------------

  /// Live-updating feed stream filtered by sort.
  ///
  /// Only `moderationStatus == 'approved'` posts are returned to readers.
  /// A `DocumentSnapshot?` cursor drives infinite-scroll pagination (null = first page).
  Stream<List<CommunityPost>> watchFeed({
    required CommunitySort sort,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
  }) {
    Query<Map<String, dynamic>> q = _posts.where(
      'moderationStatus',
      isEqualTo: ModerationStatus.approved.label,
    );
    switch (sort) {
      case CommunitySort.recent:
        q = q.orderBy('createdAt', descending: true);
        break;
      case CommunitySort.topVoted:
        q = q.orderBy('score', descending: true).orderBy('createdAt', descending: true);
        break;
      case CommunitySort.relevant:
        q = q.orderBy('hot', descending: true);
        break;
    }
    q = q.limit(limit);
    if (cursor != null) q = q.startAfterDocument(cursor);
    return q.snapshots().map((snap) =>
        snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList());
  }

  /// Author-scoped stream for "My Posts" (all statuses, including flagged).
  Stream<List<CommunityPost>> watchMyPosts(String uid) {
    return _posts
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList());
  }

  // ---------------------------------------------------------------------------
  // Post CRUD
  // ---------------------------------------------------------------------------

  /// Pre-generate a Firestore post ID (for uploading Storage images before
  /// creating the doc).
  String generatePostId() => _posts.doc().id;

  Future<String> createPost({
    required UserSignedIn author,
    required String description,
    required double latitude,
    required double longitude,
    String? placeName,
    List<String> imageURLs = const [],
    List<String> imagePaths = const [],
    String? postId,
  }) async {
    assert(imageURLs.length <= maxPostImages);
    assert(imagePaths.length <= maxPostImages);
    await ensureUserExists(author);

    final now = DateTime.now();
    final ref = postId != null ? _posts.doc(postId) : _posts.doc();
    final post = CommunityPost(
      id: ref.id,
      authorUid: author.uid,
      authorName: author.displayName ?? 'Anonymous',
      authorPhotoURL: author.photoURL,
      description: description,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
      imageURLs: imageURLs,
      imagePaths: imagePaths,
      createdAt: now,
      updatedAt: now,
      editLockExpiresAt: now.add(_editLockWindow),
    );
    await ref.set(post.toFirestore());

    await _users.doc(author.uid).update({'postCount': FieldValue.increment(1)});
    return ref.id;
  }

  /// Edit a post (author-only, enforced by Firestore rules + client-side guard).
  /// Fails if [CommunityPost.canEdit] is false.
  Future<void> updatePost(
    CommunityPost post, {
    String? description,
    String? placeName,
    List<String>? imageURLs,
    List<String>? imagePaths,
  }) async {
    if (!post.canEdit) {
      throw StateError('Edit window closed for post ${post.id}');
    }
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    };
    if (description != null) patch['description'] = description;
    if (placeName != null) patch['placeName'] = placeName;
    if (imageURLs != null) {
      assert(imageURLs.length <= maxPostImages);
      patch['imageURLs'] = imageURLs;
    }
    if (imagePaths != null) {
      assert(imagePaths.length <= maxPostImages);
      patch['imagePaths'] = imagePaths;
    }
    await _posts.doc(post.id).update(patch);
  }

  /// Delete a post + its Storage images + vote subcollection.
  /// Author-only (Firestore rules); admin dashboard bypasses via admin SDK.
  Future<void> deletePost(CommunityPost post) async {
    final batch = _db.batch();

    // Delete vote subcollection docs.
    final votesSnap = await _posts.doc(post.id).collection('votes').get();
    for (final d in votesSnap.docs) {
      batch.delete(d.reference);
    }

    // Decrement author's postCount (only if positive to avoid underflow).
    final userRef = _users.doc(post.authorUid);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      final count = userSnap.data()?['postCount'] as int? ?? 0;
      if (count > 0) {
        batch.update(userRef, {'postCount': count - 1});
      }
    }

    // Delete comments under this post.
    final commentsSnap =
        await _comments.where('postId', isEqualTo: post.id).get();
    for (final c in commentsSnap.docs) {
      final commentVotesSnap =
          await _comments.doc(c.id).collection('votes').get();
      for (final cv in commentVotesSnap.docs) {
        batch.delete(cv.reference);
      }
      batch.delete(c.reference);
    }

    batch.delete(_posts.doc(post.id));
    await batch.commit();

    // Best-effort Storage image cleanup (out of batch — separate service).
    await _deleteStorageObjects(post.imagePaths);
    for (final c in commentsSnap.docs) {
      final imagePath = c.data()['imagePath'] as String?;
      if (imagePath != null) await _deleteStorageObject(imagePath);
    }
  }

  Stream<CommunityPost> watchPost(String id) {
    return _posts.doc(id).snapshots().map((d) => CommunityPost.fromFirestore(d));
  }

  // ---------------------------------------------------------------------------
  // Votes (posts + comments)
  // ---------------------------------------------------------------------------

  /// Cast, flip, or remove the current user's vote on a post.
  ///
  /// Runs inside a transaction so the post's counters and the user's vote doc
  /// are updated atomically. `newValue == none` means "remove my vote."
  Future<void> votePost(String postId, VoteValue newValue, String uid) async {
    final postRef = _posts.doc(postId);
    final voteRef = postRef.collection('votes').doc(uid);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;
      final post = CommunityPost.fromFirestore(postSnap);
      final voteSnap = await tx.get(voteRef);
      final prevSign = (voteSnap.data()?['value'] as int?) ?? 0;
      final newSign = newValue.sign;

      if (prevSign == newSign) return; // no-op (e.g. up → up)

      int up = post.upvoteCount;
      int down = post.downvoteCount;
      // Revert previous.
      if (prevSign == 1) up--;
      if (prevSign == -1) down--;
      // Apply new.
      if (newSign == 1) up++;
      if (newSign == -1) down++;
      final score = up - down;
      final hot = _hotScore(score, post.createdAt);

      tx.update(postRef, {
        'upvoteCount': up,
        'downvoteCount': down,
        'score': score,
        'hot': hot,
      });
      if (newSign == 0) {
        if (voteSnap.exists) tx.delete(voteRef);
      } else {
        tx.set(voteRef, {
          'value': newSign,
          'votedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Same transaction pattern for comment votes.
  Future<void> voteComment(
      String commentId, VoteValue newValue, String uid) async {
    final commentRef = _comments.doc(commentId);
    final voteRef = commentRef.collection('votes').doc(uid);

    await _db.runTransaction((tx) async {
      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) return;
      final comment = CommunityComment.fromFirestore(commentSnap);
      final voteSnap = await tx.get(voteRef);
      final prevSign = (voteSnap.data()?['value'] as int?) ?? 0;
      final newSign = newValue.sign;

      if (prevSign == newSign) return;

      int up = comment.upvoteCount;
      int down = comment.downvoteCount;
      if (prevSign == 1) up--;
      if (prevSign == -1) down--;
      if (newSign == 1) up++;
      if (newSign == -1) down++;
      final score = up - down;

      tx.update(commentRef, {
        'upvoteCount': up,
        'downvoteCount': down,
        'score': score,
      });
      if (newSign == 0) {
        if (voteSnap.exists) tx.delete(voteRef);
      } else {
        tx.set(voteRef, {
          'value': newSign,
          'votedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Batch-fetch the current user's votes on a list of posts/comments for UI
  /// state (which arrow should be highlighted).
  Future<Map<String, VoteValue>> myVotesForPosts(
      Iterable<String> postIds, String uid) async {
    final result = <String, VoteValue>{};
    for (final id in postIds) {
      final snap = await _posts.doc(id).collection('votes').doc(uid).get();
      if (snap.exists) {
        result[id] = VoteValueExt.fromSign(snap.data()?['value'] as int?);
      }
    }
    return result;
  }

  Future<Map<String, VoteValue>> myVotesForComments(
      Iterable<String> commentIds, String uid) async {
    final result = <String, VoteValue>{};
    for (final id in commentIds) {
      final snap = await _comments.doc(id).collection('votes').doc(uid).get();
      if (snap.exists) {
        result[id] = VoteValueExt.fromSign(snap.data()?['value'] as int?);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// Live-updating flat comment list for a post, sorted by score (top first).
  Stream<List<CommunityComment>> watchComments(String postId,
      {int limit = 50}) {
    return _comments
        .where('postId', isEqualTo: postId)
        .where('moderationStatus',
            isEqualTo: ModerationStatus.approved.label)
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityComment.fromFirestore(d)).toList());
  }

  Future<String> addComment({
    required UserSignedIn author,
    required String postId,
    String? text,
    String? imageURL,
    String? imagePath,
  }) async {
    assert(text != null || imageURL != null,
        'Comment must have either text or image');
    await ensureUserExists(author);

    final now = DateTime.now();
    final ref = _comments.doc();
    final comment = CommunityComment(
      id: ref.id,
      postId: postId,
      authorUid: author.uid,
      authorName: author.displayName ?? 'Anonymous',
      authorPhotoURL: author.photoURL,
      text: text,
      imageURL: imageURL,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
      editLockExpiresAt: now.add(_editLockWindow),
    );
    await ref.set(comment.toFirestore());

    await _posts.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
    return ref.id;
  }

  Future<void> updateComment(
    CommunityComment comment, {
    String? text,
    String? imageURL,
    String? imagePath,
  }) async {
    if (!comment.canEdit) {
      throw StateError('Edit window closed for comment ${comment.id}');
    }
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    };
    if (text != null) patch['text'] = text;
    if (imageURL != null) patch['imageURL'] = imageURL;
    if (imagePath != null) patch['imagePath'] = imagePath;
    await _comments.doc(comment.id).update(patch);
  }

  Future<void> deleteComment(CommunityComment comment) async {
    final batch = _db.batch();
    final votesSnap =
        await _comments.doc(comment.id).collection('votes').get();
    for (final v in votesSnap.docs) {
      batch.delete(v.reference);
    }
    batch.delete(_comments.doc(comment.id));
    await batch.commit();

    await _posts.doc(comment.postId).update({
      'commentCount': FieldValue.increment(-1),
    });

    if (comment.imagePath != null) {
      await _deleteStorageObject(comment.imagePath!);
    }
  }

  // ---------------------------------------------------------------------------
  // Reports (Phase A.4 — moderation queue input)
  // ---------------------------------------------------------------------------

  Future<void> reportPost({
    required String postId,
    required String reporterUid,
    String? reason,
  }) async {
    // One report per user per post — guard against spam.
    final existing = await _reports
        .where('postId', isEqualTo: postId)
        .where('reporterUid', isEqualTo: reporterUid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _reports.add({
      'postId': postId,
      'reporterUid': reporterUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    await _posts.doc(postId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ---------------------------------------------------------------------------
  // Storage helpers
  // ---------------------------------------------------------------------------

  /// Upload image bytes to `posts/{postId}/image_{index}.{ext}`.
  Future<({String url, String path})?> uploadPostImage(
    String postId,
    Uint8List bytes, {
    int index = 0,
    String ext = 'jpg',
  }) async {
    final path = 'posts/$postId/image_$index.$ext';
    return _uploadBytes(bytes, path, ext);
  }

  /// Upload image bytes to `comments/{commentId}/image.{ext}`.
  Future<({String url, String path})?> uploadCommentImage(
    String commentId,
    Uint8List bytes, {
    String ext = 'jpg',
  }) async {
    final path = 'comments/$commentId/image.$ext';
    return _uploadBytes(bytes, path, ext);
  }

  /// Shared upload: writes [bytes] to a temp file, calls [putFile], then
  /// retries [getDownloadURL] up to 3 times to work around transient
  /// `object-not-found` race conditions on some Storage deployments.
  Future<({String url, String path})?> _uploadBytes(
    Uint8List bytes,
    String path,
    String ext,
  ) async {
    if (bytes.isEmpty) return null;
    final contentType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final ref = _storage.ref().child(path);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'upload_${path.hashCode}.$ext'));
    await tempFile.writeAsBytes(bytes);

    try {
      await ref.putFile(
        tempFile,
        SettableMetadata(contentType: contentType),
      );

      // Retry getDownloadURL up to 3 times with backoff
      const maxRetries = 3;
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final url = await ref.getDownloadURL();
          return (url: url, path: path);
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found' && attempt < maxRetries - 1) {
            await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }
      return null;
    } finally {
      if (tempFile.existsSync()) await tempFile.delete();
    }
  }

  Future<void> _deleteStorageObject(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // Best-effort; ref may already be gone.
    }
  }

Future<void> _deleteStorageObjects(Iterable<String> paths) async {
    await Future.wait(paths.map(_deleteStorageObject));
  }
}