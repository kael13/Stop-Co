import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_input.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/auth_action_providers.dart';
import '../data/auth_providers.dart';

final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _nameController = TextEditingController();

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent — check your inbox'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guestSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInAsGuest();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final needsVerification =
        user != null && !user.emailVerified && !user.isAnonymous;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final headerHeight = constraints.maxHeight * 0.38;
                  return Stack(
                    children: [
                      _GradientHeader(height: headerHeight),
                      Positioned.fill(
                        child: Column(
                          children: [
                            SizedBox(height: headerHeight - 60),
                            Expanded(
                              child: _FormCard(
                                isLogin: _isLogin,
                                isLoading: _isLoading,
                                error: _error,
                                onSubmit: _submit,
                                onGoogle: _googleSignIn,
                                onGuest: _guestSignIn,
                                onToggleMode: () =>
                                    setState(() => _isLogin = !_isLogin),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (needsVerification)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _VerificationBanner(
                onResend: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(resendVerificationEmailActionProvider.future);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Verification email resent'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              e.toString().replaceAll('Exception: ', '')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                onRefresh: () =>
                    ref.read(reloadCurrentUserActionProvider.future),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
            ),
          Positioned(
            top: needsVerification
                ? MediaQuery.of(context).padding.top + AppSpacing.xl + 48
                : MediaQuery.of(context).padding.top + AppSpacing.md,
            left: 0,
            right: 0,
            child: _BrandHeader().animate().fadeIn(
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ).slideY(begin: -0.05, end: 0, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final double height;
  const _GradientHeader({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primary,
            context.secondary,
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Stop-Co',
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          "Don't miss your stop",
          style: AppTypography.secondary.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onGuest;
  final VoidCallback onToggleMode;
  final bool isDark;

  const _FormCard({
    required this.isLogin,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.onGoogle,
    required this.onGuest,
    required this.onToggleMode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final staggerBase = 80.ms;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLogin ? 'Welcome back' : 'Create your account',
              style: AppTypography.largeTitle.copyWith(color: context.textPrimary),
            ).animate().fadeIn(delay: staggerBase).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 320.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 4),
            Text(
              isLogin
                  ? 'Sign in to save your destinations'
                  : 'Join Stop-Co in seconds',
              style: AppTypography.secondary.copyWith(color: context.textSecondary),
            ).animate().fadeIn(delay: staggerBase + 60.ms),
            const SizedBox(height: AppSpacing.xl),
            if (!isLogin) ...[
              AppInput(
                label: 'Name',
                hint: 'Your name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: staggerBase + 120.ms).slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 280.ms,
                  ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppInput(
              label: 'Email',
              hint: 'your@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
            ).animate().fadeIn(delay: staggerBase + 180.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 280.ms,
                ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmit,
            ).animate().fadeIn(delay: staggerBase + 240.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 280.ms,
                ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                error!,
                style: AppTypography.secondary.copyWith(color: context.error),
              ).animate().shake(delay: 200.ms, hz: 4, offset: const Offset(4, 0)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: isLogin ? 'Log In' : 'Create Account',
              onPressed: onSubmit,
              isLoading: isLoading,
            ).animate().fadeIn(delay: staggerBase + 300.ms),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Continue with Google',
              onPressed: onGoogle,
              isSecondary: true,
              icon: Icons.g_mobiledata,
            ).animate().fadeIn(delay: staggerBase + 360.ms),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Continue as Guest',
              onPressed: onGuest,
              isSecondary: true,
              icon: Icons.person_outline,
            ).animate().fadeIn(delay: staggerBase + 420.ms),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: onToggleMode,
                child: Text(
                  isLogin
                      ? "Don't have an account? Sign up"
                      : 'Already have an account? Log in',
                ),
              ),
            ).animate().fadeIn(delay: staggerBase + 480.ms),
          ],
        ),
      ),
    );
  }
}

/// Persistent banner shown on AuthScreen when the user is signed in via
/// email/password but hasn't verified their email yet. Google users are
/// auto-verified and never see this.
class _VerificationBanner extends StatelessWidget {
  final VoidCallback onResend;
  final Future<void> Function() onRefresh;

  const _VerificationBanner({required this.onResend, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      color: context.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Verify your email to post in Community',
                    style: AppTypography.secondary.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Check your inbox and tap the verification link, then refresh.',
              style: AppTypography.secondary.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onResend,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Resend', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton.tonal(
                  onPressed: onRefresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: context.primary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('I\'ve verified',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}