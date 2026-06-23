import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

/// Action that reloads the current Firebase user so `emailVerified` reflects
/// the latest server-side state. Call when the user taps "I've verified —
/// Refresh" on the AuthScreen verification banner.
///
/// After this resolves, `authStateProvider` re-emits with the updated
/// `emailVerified` flag, flipping the Community write gate.
final reloadCurrentUserActionProvider = FutureProvider<void>((ref) async {
  final auth = ref.read(authRepositoryProvider);
  await auth.reloadCurrentUser();
});

/// Action that resends the verification email (Firebase-throttled).
final resendVerificationEmailActionProvider =
    FutureProvider<void>((ref) async {
  final auth = ref.read(authRepositoryProvider);
  await auth.resendEmailVerification();
});