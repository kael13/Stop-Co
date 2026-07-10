import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../data/poi.dart';

class PoiBottomSheet extends StatelessWidget {
  final Poi poi;
  final VoidCallback? onNavigate;

  const PoiBottomSheet({super.key, required this.poi, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      poi.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: AppTypography.title.copyWith(
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        poi.categoryLabel,
                        style: AppTypography.secondary.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: '${poi.latitude.toStringAsFixed(5)}, ${poi.longitude.toStringAsFixed(5)}',
            ),
            if (poi.hasTag('opening_hours'))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: poi.tags['opening_hours']!,
                ),
              ),
            if (poi.hasTag('phone'))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _DetailRow(
                  icon: Icons.phone_rounded,
                  label: poi.tags['phone']!,
                ),
              ),
            if (poi.hasTag('website'))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _DetailRow(
                  icon: Icons.language_rounded,
                  label: poi.tags['website']!,
                  maxLines: 1,
                ),
              ),
            if (_formatAddress(poi.tags).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _DetailRow(
                  icon: Icons.map_rounded,
                  label: _formatAddress(poi.tags),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, String> tags) {
    final street = tags['addr:street'] ?? '';
    final housenumber = tags['addr:housenumber'] ?? '';
    final city = tags['addr:city'] ?? '';
    final parts = [
      if (street.isNotEmpty) '$housenumber $street'.trim(),
      if (city.isNotEmpty) city,
    ];
    return parts.isNotEmpty ? parts.join(', ') : '';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.secondary.copyWith(
              color: context.textSecondary,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
