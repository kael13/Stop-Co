/// Vote value for a post or comment: `+1` (upvote) or `-1` (downvote).
///
/// A user has at most one vote doc per target: `posts/{postId}/votes/{uid}` or
/// `comments/{commentId}/votes/{uid}`. Toggling the same value removes the vote
/// (value becomes `0`).
enum VoteValue { up, down, none }

extension VoteValueExt on VoteValue {
  int get sign {
    switch (this) {
      case VoteValue.up:
        return 1;
      case VoteValue.down:
        return -1;
      case VoteValue.none:
        return 0;
    }
  }

  static VoteValue fromSign(int? sign) {
    if (sign == null || sign == 0) return VoteValue.none;
    return sign > 0 ? VoteValue.up : VoteValue.down;
  }
}