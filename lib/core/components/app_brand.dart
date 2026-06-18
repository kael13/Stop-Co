import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AppBrand extends StatelessWidget {
  final double iconSize;
  final TextStyle? textStyle;

  const AppBrand({
    super.key,
    this.iconSize = 28,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_active_rounded,
          color: AppColors.electricBlue,
          size: iconSize,
        ),
        const SizedBox(width: 8),
        Text(
          AppConstants.appName,
          style: textStyle ?? AppTypography.largeTitle.copyWith(
            color: AppColors.deepSlate,
          ),
        ),
      ],
    );
  }
}
