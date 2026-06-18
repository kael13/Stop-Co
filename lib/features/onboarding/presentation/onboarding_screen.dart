import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/components/app_button.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/onboarding_provider.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await completeOnboarding(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final showSkip = _currentPage < _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: showSkip
                ? TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.textTertiary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          _PageIndicator(
            count: _slides.length,
            current: _currentPage,
          ),
          const Spacer(),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLast = _currentPage == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: AppButton(
        label: isLast ? 'Get Started' : 'Next',
        onPressed: isLast ? _finish : _nextPage,
      ),
    );
  }
}

final _slides = <Widget>[
  OnboardingPage(
    title: 'Never Miss Your Stop',
    subtitle:
        'Set a destination alarm, and Stop-Co quietly watches your commute so you can relax.',
    visual: _SlideIcon(Icons.notifications_active_rounded),
  ),
  OnboardingPage(
    title: 'Pick Any Spot',
    subtitle:
        'Drop a pin on the map or search for an address — choose exactly where you want the alarm.',
    visual: _SlideIcon(Icons.location_on_rounded),
  ),
  OnboardingPage(
    title: 'Arrive, Get Alerted',
    subtitle:
        'When you enter your chosen zone, the alarm fires with sound, vibration, or both.',
    visual: _SlideIcon(Icons.alarm_on_rounded),
  ),
  OnboardingPage(
    title: 'Start Your Journey',
    subtitle: "Ready to never miss a stop again? Let's go!",
    visual: LottieBuilder.asset(
      'assets/animations/onboarding_arrival.json',
      fit: BoxFit.contain,
    ),
  ),
];

class _SlideIcon extends StatefulWidget {
  final IconData icon;

  const _SlideIcon(this.icon);

  @override
  State<_SlideIcon> createState() => _SlideIconState();
}

class _SlideIconState extends State<_SlideIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
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
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          widget.icon,
          size: 120,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}
