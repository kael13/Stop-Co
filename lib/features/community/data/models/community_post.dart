import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/moderation_status.dart';

/// A community post.
///
/// Storage layout:
/// - `imageURLs` / `imagePaths` — max 3 entries each, parallel arrays.
/// - `score` = `upvoteCount - downvoteCount` (denormalized via Firestore Transaction).
/// - `hot` — HN-style ranking score for the "Relevant" sort.
/// - `editLockExpiresAt` — `createdAt + 15 min`; editing is disabled afterward.
/// - `moderationStatus` — `approved` by default; auto-flagged by SafeSearch (Phase A.4).
class CommunityPost {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoURL;
  final String description;
  final double latitude;
  final double longitude;
  final String? placeName;
  final List<String> imageURLs;
  final List<String> imagePaths;
  final int upvoteCount;
  final int downvoteCount;
  final int score;
  final double hot;
  final int commentCount;
  final ModerationStatus moderationStatus;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime editLockExpiresAt;
  final bool isEdited;

  const CommunityPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoURL,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.imageURLs = const [],
    this.imagePaths = const [],
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.hot = 0,
    this.commentCount = 0,
    this.moderationStatus = ModerationStatus.approved,
    this.reportCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.editLockExpiresAt,
    this.isEdited = false,
  });

  bool get canEdit => DateTime.now().isBefore(editLockExpiresAt);

  factory CommunityPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return CommunityPost(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonymous',
      authorPhotoURL: data['authorPhotoURL'] as String?,
      description: data['description'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      placeName: data['placeName'] as String?,
      imageURLs: List<String>.from(data['imageURLs'] as List? ?? const []),
      imagePaths: List<String>.from(data['imagePaths'] as List? ?? const []),
      upvoteCount: data['upvoteCount'] as int? ?? 0,
      downvoteCount: data['downvoteCount'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
      hot: (data['hot'] as num?)?.toDouble() ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      moderationStatus: ModerationStatus.fromString(data['moderationStatus']),
      reportCount: data['reportCount'] as int? ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
      editLockExpiresAt: (data['editLockExpiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(minutes: 15)),
      isEdited: data['isEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'imageURLs': imageURLs,
      'imagePaths': imagePaths,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'score': score,
      'hot': hot,
      'commentCount': commentCount,
      'moderationStatus': moderationStatus.label,
      'reportCount': reportCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'editLockExpiresAt': Timestamp.fromDate(editLockExpiresAt),
      'isEdited': isEdited,
    };
  }

  CommunityPost copyWith({
    String? description,
    String? placeName,
    List<String>? imageURLs,
    List<String>? imagePaths,
    int? upvoteCount,
    int? downvoteCount,
    int? score,
    double? hot,
    int? commentCount,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return CommunityPost(
      id: id,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoURL: authorPhotoURL,
      description: description ?? this.description,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName ?? this.placeName,
      imageURLs: imageURLs ?? this.imageURLs,
      imagePaths: imagePaths ?? this.imagePaths,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      score: score ?? this.score,
      hot: hot ?? this.hot,
      commentCount: commentCount ?? this.commentCount,
      moderationStatus: moderationStatus,
      reportCount: reportCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editLockExpiresAt: editLockExpiresAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}