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
        isAnonymous: user.isAnonymous,
      );
    }
    return null;
  });
});

class UserSignedIn {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const UserSignedIn({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}
