import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/moderation_status.dart';

/// A flat comment attached to a post (no nesting).
///
/// Same counter/transaction pattern as [CommunityPost]:
/// - `score` = `upvoteCount - downvoteCount` (denormalized via Transaction).
/// - `editLockExpiresAt` — `createdAt + 15 min`.
/// - Max 1 image per comment (for lightweight UI).
class CommunityComment {
  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String? authorPhotoURL;
  final String? text;
  final String? imageURL;
  final String? imagePath;
  final int upvoteCount;
  final int downvoteCount;
  final int score;
  final ModerationStatus moderationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime editLockExpiresAt;
  final bool isEdited;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoURL,
    this.text,
    this.imageURL,
    this.imagePath,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.moderationStatus = ModerationStatus.approved,
    required this.createdAt,
    required this.updatedAt,
    required this.editLockExpiresAt,
    this.isEdited = false,
  });

  bool get canEdit => DateTime.now().isBefore(editLockExpiresAt);

  factory CommunityComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return CommunityComment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonymous',
      authorPhotoURL: data['authorPhotoURL'] as String?,
      text: data['text'] as String?,
      imageURL: data['imageURL'] as String?,
      imagePath: data['imagePath'] as String?,
      upvoteCount: data['upvoteCount'] as int? ?? 0,
      downvoteCount: data['downvoteCount'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
      moderationStatus: ModerationStatus.fromString(data['moderationStatus']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      editLockExpiresAt: (data['editLockExpiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(minutes: 15)),
      isEdited: data['isEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'text': text,
      'imageURL': imageURL,
      'imagePath': imagePath,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'score': score,
      'moderationStatus': moderationStatus.label,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'editLockExpiresAt': Timestamp.fromDate(editLockExpiresAt),
      'isEdited': isEdited,
    };
  }
}