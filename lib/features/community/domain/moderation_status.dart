/// Moderation status for community posts and comments.
///
/// - `approved` — publicly visible in the feed (default on creation).
/// - `flagged` — hidden from public feed; still visible to the author with a
///   "Pending review" banner. Set by an automated SafeSearch Cloud Function
///   (Phase A.4) or escalated via the report queue.
/// - `removed` — hidden from everyone; set by the future moderation dashboard.
enum ModerationStatus {
  approved,
  flagged,
  removed;

  static ModerationStatus fromString(String? value) {
    switch (value) {
      case 'flagged':
        return ModerationStatus.flagged;
      case 'removed':
        return ModerationStatus.removed;
      case 'approved':
      default:
        return ModerationStatus.approved;
    }
  }

  String get label {
    switch (this) {
      case ModerationStatus.approved:
        return 'approved';
      case ModerationStatus.flagged:
        return 'flagged';
      case ModerationStatus.removed:
        return 'removed';
    }
  }
}