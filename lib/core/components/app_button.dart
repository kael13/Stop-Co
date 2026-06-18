import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final bool isSecondary;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.isSecondary = false,
    this.icon,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.isDestructive
        ? AppColors.error
        : widget.isSecondary
            ? Colors.transparent
            : colorScheme.primary;
    final foregroundColor = widget.isDestructive || !widget.isSecondary
        ? AppColors.white
        : colorScheme.primary;
    final borderSide = widget.isSecondary
        ? BorderSide(color: colorScheme.primary, width: 1.5)
        : BorderSide.none;

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) {
              HapticFeedback.lightImpact();
              _controller.forward();
            }
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) => _controller.reverse()
          : null,
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width ?? double.infinity,
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.fromBorderSide(borderSide),
            boxShadow: widget.isSecondary || widget.isDestructive
                ? null
                : [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foregroundColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: foregroundColor, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.button.copyWith(
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
