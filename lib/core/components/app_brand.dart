import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../constants/app_constants.dart';

class AppBrand extends StatelessWidget {
  final bool showTagline;

  const AppBrand({super.key, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            "Don't miss your stop",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}
