/// Sort modes for the community feed.
///
/// - `recent` — newest first; backed by the `moderationStatus ASC, createdAt DESC` index.
/// - `topVoted` — highest net score first; backed by the
///   `moderationStatus ASC, score DESC, createdAt DESC` index.
/// - `relevant` — HN-style hot ranking; backed by the
///   `moderationStatus ASC, hot DESC` index.
enum CommunitySort {
  recent,
  topVoted,
  relevant;

  String get label {
    switch (this) {
      case CommunitySort.recent:
        return 'Recent';
      case CommunitySort.topVoted:
        return 'Top Voted';
      case CommunitySort.relevant:
        return 'Relevant';
    }
  }
}