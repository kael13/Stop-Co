import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/theme_colors.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration entranceDuration = Duration(milliseconds: 320);
  static const Duration cardDuration = Duration(milliseconds: 280);
  static const Duration microDuration = Duration(milliseconds: 150);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;

  static Duration staggerDelay(int index, [int baseMs = 60]) =>
      Duration(milliseconds: baseMs * index);

  static Duration staggerBy(int index, [Duration base = const Duration(milliseconds: 60)]) =>
      base * index;
}

extension AnimatePresets on Widget {
  Widget fadeSlideUp({Duration delay = Duration.zero}) => animate(
        delay: delay,
      )
          .fadeIn(duration: AppAnimations.entranceDuration, curve: AppAnimations.entranceCurve)
          .slideY(
            begin: 0.08,
            end: 0,
            duration: AppAnimations.entranceDuration,
            curve: AppAnimations.entranceCurve,
          );

  Widget cardEntrance({Duration delay = Duration.zero}) => animate(
        delay: delay,
      )
          .fadeIn(duration: AppAnimations.cardDuration, curve: AppAnimations.entranceCurve)
          .scaleXY(
            begin: 0.96,
            end: 1.0,
            duration: AppAnimations.cardDuration,
            curve: AppAnimations.bounceCurve,
          );

  Widget scaleTapHaptic({double begin = 1.0, double end = 0.97}) => animate(
        onPlay: (c) => c.forward(),
        onComplete: (c) => c.reverse(),
      ).scaleXY(
        begin: begin,
        end: end,
        duration: AppAnimations.microDuration,
      );

  Widget subtleShimmerSweep({Duration delay = Duration.zero}) => animate(
        delay: delay,
      ).shimmer(
        duration: 1200.ms,
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.15),
        angle: 0.2,
      );
}

Widget buildShimmerBox({
  required BuildContext context,
  required double width,
  required double height,
  double radius = 8,
}) {
  return Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

Widget buildShimmerLine({
  required BuildContext context,
  required double width,
  double height = 12,
  double radius = 6,
}) =>
    buildShimmerBox(
      context: context,
      width: width,
      height: height,
      radius: radius,
    );