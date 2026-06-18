import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_input.dart';
import '../../../core/components/app_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const AppBrand(),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Don't miss your stop",
                style: AppTypography.secondary.copyWith(
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl * 1.5),
              if (!_isLogin)
                AppInput(
                  label: 'Name',
                  hint: 'Your name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
              if (!_isLogin) const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Email',
                hint: 'your@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: _submit,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.secondary.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _isLogin ? 'Log In' : 'Create Account',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Continue with Google',
                onPressed: _googleSignIn,
                isSecondary: true,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Continue as Guest',
                onPressed: _guestSignIn,
                isSecondary: true,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Log in',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
