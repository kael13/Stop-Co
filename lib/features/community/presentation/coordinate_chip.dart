import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import 'map_preview_screen.dart';

/// Tappable coordinate chip shown on PostCards. Renders "📍 14.5912, 120.9789"
/// and pushes [MapPreviewScreen] on tap.
class CoordinateChip extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? placeName;
  final bool compact;

  const CoordinateChip({
    super.key,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = placeName != null
        ? '📍 $placeName'
        : '📍 ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MapPreviewScreen(
                latitude: latitude,
                longitude: longitude,
                placeName: placeName,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: compact ? 14 : 16,
                color: context.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  text,
                  style: (compact
                          ? AppTypography.secondary
                          : AppTypography.secondary)
                      .copyWith(color: context.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.chevron_right_rounded,
                size: compact ? 14 : 16,
                color: context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}