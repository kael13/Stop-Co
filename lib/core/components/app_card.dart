import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    return Padding(
      padding: theme.cardTheme.margin ?? EdgeInsets.zero,
      child: Material(
        color: cardColor,
        borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape! as RoundedRectangleBorder)
                .borderRadius
                .resolve(Directionality.of(context))
            : BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
              ? (theme.cardTheme.shape! as RoundedRectangleBorder)
                  .borderRadius
                  .resolve(Directionality.of(context))
              : BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
