import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});


final authStateProvider = StreamProvider<UserSignedIn?>((ref) {
  final auth = ref.read(authRepositoryProvider);
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

class UserSignedIn {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final bool emailVerified;

  const UserSignedIn({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
    this.emailVerified = false,
  });

  /// Convenience: can this user write to the Community feature?
  /// Requires a non-anonymous, verified account.
  bool get canWriteCommunity =>
      !isAnonymous && emailVerified;
}
