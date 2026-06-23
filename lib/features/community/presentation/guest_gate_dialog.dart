import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../auth/presentation/auth_screen.dart';

/// Option-B dialog shown when an unauthenticated or anonymous user taps a
/// Community write surface (post / vote / comment).
///
/// "Guests can browse posts, but you need a verified email or Google account
/// to post, upvote, downvote, or comment."
///
/// [Maybe later] closes the dialog; [Sign in] pushes the existing AuthScreen.
///
/// The write gate itself is enforced at the Firestore rule level
/// (`isVerifiedWriter()`); this dialog is the client-side UX guard that
/// prevents unverified users from hitting a raw permission-denied error.
Future<void> showGuestGateDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _GuestGateDialog(),
  );
}

class _GuestGateDialog extends StatelessWidget {
  const _GuestGateDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline_rounded, size: 40),
      title: const Text('Join the Community'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guests can browse posts, but you need a verified email or Google account to:',
            style: AppTypography.secondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _BulletPoint(text: 'Post', icon: Icons.edit_outlined),
          _BulletPoint(text: 'Upvote / Downvote', icon: Icons.arrow_upward_rounded),
          _BulletPoint(text: 'Comment', icon: Icons.chat_bubble_outline_rounded),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
            );
          },
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.secondary),
        ],
      ),
    );
  }
}