import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_input.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/profile_providers.dart';

class NicknameSetupScreen extends ConsumerStatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  ConsumerState<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends ConsumerState<NicknameSetupScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.length < 2) {
      setState(() => _error = 'At least 2 characters');
      return;
    }
    if (text.length > 20) {
      setState(() => _error = 'Maximum 20 characters');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    ref.read(createProfileActionProvider(text).future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.person_outline_rounded,
                size: 56,
                color: context.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppConstants.appName,
                style: AppTypography.title.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'What should we call you?',
                style: AppTypography.body.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _controller,
                hint: 'Your nickname',
                prefixIcon: Icons.edit_rounded,
                errorText: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Get started',
                isLoading: _saving,
                onPressed: _submit,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
