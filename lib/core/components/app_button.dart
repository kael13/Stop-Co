import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final bool isSecondary;
  final bool isTonal;
  final bool isText;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.isSecondary = false,
    this.isTonal = false,
    this.isText = false,
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              _controller.forward();
            }
          : null,
      onTapUp: isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: _buildButton(context, isEnabled),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isEnabled) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final minSize = Size(
      widget.width ?? double.infinity,
      AppSpacing.buttonHeight,
    );

    if (widget.isText) {
      return TextButton(
        onPressed: isEnabled ? widget.onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: widget.isDestructive
              ? colorScheme.error
              : colorScheme.primary,
          shape: shape,
        ),
        child: _buildContent(),
      );
    }

    if (widget.isSecondary) {
      return OutlinedButton(
        onPressed: isEnabled ? widget.onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1),
          shape: shape,
          minimumSize: minSize,
        ),
        child: _buildContent(),
      );
    }

    if (widget.isTonal) {
      return FilledButton.tonal(
        onPressed: isEnabled ? widget.onPressed : null,
        style: FilledButton.styleFrom(
          shape: shape,
          minimumSize: minSize,
          overlayColor: Colors.transparent,
        ),
        child: _buildContent(),
      );
    }

    return FilledButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: widget.isDestructive
            ? colorScheme.error
            : colorScheme.primary,
        foregroundColor: widget.isDestructive
            ? colorScheme.onError
            : colorScheme.onPrimary,
        shape: shape,
        elevation: 0,
        minimumSize: minSize,
        overlayColor: Colors.transparent,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(widget.label, style: AppTypography.button),
      ],
    );
  }
}
