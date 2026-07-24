import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animation/animation_presets.dart';
import '../../../core/components/app_brand.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/gps_utils.dart';
import '../../../features/profile/data/profile_providers.dart';
import '../../destination/data/destination_model.dart';
import '../../destination/data/destination_providers.dart';
import '../../destination/data/destination_repository.dart';
import '../../destination/presentation/destination_setup_screen.dart';
import '../../scheduled_trip/presentation/schedules_list_view.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../trip/data/saved_route.dart';
import '../../trip/data/saved_route_repository.dart';
import '../../trip/data/trip_model.dart';
import '../../trip/data/trip_providers.dart';
import '../../trip/data/trip_record.dart';
import '../../trip/presentation/trip_detail_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 1;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const _tabs = <_TabItem>[
    _TabItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on_rounded, label: 'Planner'),
    _TabItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Trips'),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  final _pages = const <Widget>[
    _DestinationsTab(),
    _HomeTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(
            top: BorderSide(
              color: context.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                  top: AppSpacing.xxs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_tabs.length, (index) {
                    final tab = _tabs[index];
                    final selected = _currentIndex == index;
                    if (index == 1) {
                      return const SizedBox(width: 56, height: 56);
                    }
                    return _NavBarItem(
                      icon: selected ? tab.activeIcon : tab.icon,
                      label: tab.label,
                      selected: selected,
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  }),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -12,
                child: Center(
                  child: _CenterNavButton(
                    selected: _currentIndex == 1,
                    onTap: () {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 110),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _scaleController.forward().then((_) => _scaleController.reverse());
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 24,
                color: widget.selected ? context.primary : context.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.selected ? context.primary : context.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: widget.selected ? 6 : 0,
                height: widget.selected ? 6 : 0,
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CenterNavButton({
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CenterNavButton> createState() => _CenterNavButtonState();
}

class _CenterNavButtonState extends State<_CenterNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 110),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _scaleController.forward().then((_) => _scaleController.reverse());
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.selected
                    ? context.primary
                    : context.primary.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trips',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
              color: widget.selected ? context.primary : context.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: widget.selected ? 6 : 0,
            height: widget.selected ? 6 : 0,
            decoration: BoxDecoration(
              color: context.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HomeTabHeader()
                .animate()
                .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                .slideY(begin: -0.04, end: 0, duration: 320.ms),
            Expanded(
              child: activeTrip != null
                  ? ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _ActiveTripBanner(trip: activeTrip)
                            .cardEntrance(),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _StartTripSection().fadeSlideUp(delay: 80.ms),
                        const SizedBox(height: AppSpacing.lg),
                        const _DestinationsBlock().fadeSlideUp(delay: 160.ms),
                        const SizedBox(height: AppSpacing.lg),
                        const _RoutesBlock().fadeSlideUp(delay: 200.ms),
                        const SizedBox(height: AppSpacing.lg),
                        const _RecentTripsBlock().fadeSlideUp(delay: 240.ms),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationsBlock extends ConsumerWidget {
  const _DestinationsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(recommendedDestinationsProvider);
    return destinationsAsync.when(
      loading: () => const _DestinationsSkeleton(),
      error: (_, _) => _YourStopsSection(destinations: const []),
      data: (destinations) => _YourStopsSection(destinations: destinations),
    );
  }
}

class _RecentTripsBlock extends ConsumerWidget {
  const _RecentTripsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTripsAsync = ref.watch(recentTripsProvider);
    return recentTripsAsync.when(
      loading: () => const _RecentTripsSkeleton(),
      error: (_, _) => _RecentTripsSection(trips: const []),
      data: (trips) => _RecentTripsSection(trips: trips),
    );
  }
}

class _RoutesBlock extends ConsumerWidget {
  const _RoutesBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(savedRoutesProvider);
    return routesAsync.when(
      loading: () => const _RoutesSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (routes) {
        if (routes.isEmpty) return const SizedBox.shrink();
        return _RoutesSection(routes: routes);
      },
    );
  }
}

class _RoutesSection extends StatelessWidget {
  final List<SavedRoute> routes;

  const _RoutesSection({required this.routes});

  @override
  Widget build(BuildContext context) {
    final display = routes.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Routes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...display.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: _RouteCard(route: entry.value)
              .fadeSlideUp(delay: Duration(milliseconds: 60 * entry.key)),
        )),
      ],
    );
  }
}

class _RouteCard extends ConsumerWidget {
  final SavedRoute route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints = route.waypoints;
    return AppCard(
      onTap: () {
        ref.read(activeTripProvider.notifier).startTripWithWaypoints(waypoints);
        Navigator.pushNamed(context, '/active-trip');
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.route_rounded,
              color: context.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: AppTypography.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${waypoints.length} stop${waypoints.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          if (route.isFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.star_rounded, color: context.warning, size: 20),
            ),
          Icon(Icons.play_circle_fill_rounded, color: context.primary, size: 32),
        ],
      ),
    );
  }
}

class _RoutesSkeleton extends StatelessWidget {
  const _RoutesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildShimmerLine(context: context, width: 110, height: 22, radius: 4),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          2,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              child: Row(
                children: [
                  buildShimmerBox(
                    context: context,
                    width: 44,
                    height: 44,
                    radius: AppSpacing.radiusMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildShimmerLine(context: context, width: 140, height: 14),
                        const SizedBox(height: 6),
                        buildShimmerLine(context: context, width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationsSkeleton extends StatelessWidget {
  const _DestinationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildShimmerLine(context: context, width: 96, height: 22, radius: 4),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              child: Row(
                children: [
                  buildShimmerBox(
                    context: context,
                    width: 44,
                    height: 44,
                    radius: AppSpacing.radiusMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildShimmerLine(context: context, width: 140, height: 14),
                        const SizedBox(height: 6),
                        buildShimmerLine(context: context, width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentTripsSkeleton extends StatelessWidget {
  const _RecentTripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildShimmerLine(context: context, width: 110, height: 22, radius: 4),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          2,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              child: Row(
                children: [
                  buildShimmerBox(
                    context: context,
                    width: 44,
                    height: 44,
                    radius: AppSpacing.radiusMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildShimmerLine(context: context, width: 120, height: 14),
                        const SizedBox(height: 6),
                        buildShimmerLine(context: context, width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTabHeader extends ConsumerWidget {
  const _HomeTabHeader();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(nicknameProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primary,
                      context.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  _greeting(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (nickname != null)
            Text(
              'Hi, $nickname',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(color: context.textPrimary),
            )
          else
            const AppBrand(),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            "Don't miss your stop",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _StartTripSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you heading?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Set Destination',
          icon: Icons.near_me_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DestinationSetupScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _YourStopsSection extends ConsumerWidget {
  final List<Destination> destinations;

  const _YourStopsSection({required this.destinations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (destinations.isEmpty) {
      return _EmptyDestinationsPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stops',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...destinations.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: _HomeDestinationCard(destination: entry.value)
              .fadeSlideUp(delay: Duration(milliseconds: 60 * entry.key)),
        )),
      ],
    );
  }
}

class _HomeDestinationCard extends ConsumerWidget {
  final Destination destination;

  const _HomeDestinationCard({required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () {
        ref.read(activeTripProvider.notifier).startTrip(destination);
        Navigator.pushNamed(context, '/active-trip');
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: context.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: AppTypography.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${destination.alertRadius.round()}m radius',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          if (destination.isFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.star_rounded, color: context.warning, size: 20),
            ),
          Icon(Icons.play_circle_fill_rounded, color: context.primary, size: 32),
        ],
      ),
    );
  }
}

class _EmptyDestinationsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.location_off_rounded, size: 48, color: context.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Saved destinations will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Set your first stop to get started.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripBanner extends ConsumerWidget {
  final ActiveTrip trip;
  const _ActiveTripBanner({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wp = trip.currentWaypoint;
    final distance = trip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final progress = distance > 0 && wp.alertRadius > 0
        ? (distance / wp.alertRadius).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: () {
        final trip = ref.read(activeTripProvider);
        if (trip == null) return;
        if (trip.status == TripStatus.alarmTriggered) {
          Navigator.pushReplacementNamed(context, '/alarm');
        } else {
          Navigator.pushNamed(context, '/active-trip');
        }
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.success.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.3, duration: 900.ms)
                    .fadeIn(),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Active Trip',
                  style: AppTypography.secondary.copyWith(
                    color: context.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              wp.name,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: context.textPrimary),
            ),
            if (trip.hasMultipleStops)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Stop ${trip.currentWaypointIndex + 1} of ${trip.totalStops}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Hero(
              tag: 'active-trip-distance',
              child: Text(
                '$distanceFormatted away',
                style: AppTypography.distance.copyWith(
                  color: context.primary,
                  fontSize: 48,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(activeTripProvider.notifier).cancelTrip();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.error,
                  side: BorderSide(color: context.error),
                ),
                child: const Text('Cancel Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PlannerSegment { destinations, schedules, routes }

class _DestinationsTab extends ConsumerStatefulWidget {
  const _DestinationsTab();

  @override
  ConsumerState<_DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends ConsumerState<_DestinationsTab> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  _PlannerSegment _selectedSegment = _PlannerSegment.destinations;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete ${_selectedIds.length} destination${_selectedIds.length == 1 ? '' : 's'}?',
        ),
        content: const Text(
          'These destinations will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(destinationRepositoryProvider);
      for (final id in _selectedIds) {
        await repo.delete(id);
      }
      _exitSelectionMode();
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(destinationListProvider);
    final activeTrip = ref.watch(activeTripProvider);
    final destinations = destinationsAsync.valueOrNull ?? [];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DestinationSetupScreen(
                showScheduledTrip: _selectedSegment == _PlannerSegment.schedules,
              ),
            ),
          );
          if (result == 'scheduled' && mounted) {
            setState(() => _selectedSegment = _PlannerSegment.schedules);
          }
        },
        child: Icon(
          _selectedSegment == _PlannerSegment.schedules
              ? Icons.calendar_month_rounded
              : _selectedSegment == _PlannerSegment.routes
                  ? Icons.route_rounded
                  : Icons.add_location_alt_rounded,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Planner',
                    style: AppTypography.largeTitle,
                  ),
                  if (_isSelectionMode)
                    TextButton(
                      onPressed: _exitSelectionMode,
                      child: const Text('Cancel'),
                    )
                  else if (_selectedSegment == _PlannerSegment.destinations)
                    Text(
                      '${destinations.length} saved',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedButton<_PlannerSegment>(
                segments: const [
                  ButtonSegment(
                    value: _PlannerSegment.destinations,
                    label: Text('Destinations'),
                    icon: Icon(Icons.location_on_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: _PlannerSegment.routes,
                    label: Text('Routes'),
                    icon: Icon(Icons.route_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: _PlannerSegment.schedules,
                    label: Text('Schedules'),
                    icon: Icon(Icons.calendar_month_outlined, size: 16),
                  ),
                ],
                selected: {_selectedSegment},
                onSelectionChanged: (selected) => setState(() => _selectedSegment = selected.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.tileRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_selectedSegment == _PlannerSegment.destinations)
              Expanded(
                child: destinations.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          AppCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Center(
                                child: Text(
                                  'No saved destinations yet.\nSet one to get started.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textTertiary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: destinations.map((dest) {
                          final isActive = dest.id == activeTrip?.currentWaypoint.id;
                          return _DestinationTile(
                            destination: dest,
                            isActive: isActive,
                            isSelected: _selectedIds.contains(dest.id),
                            isSelectionMode: _isSelectionMode,
                            onLongPress: () => _toggleSelection(dest.id),
                          );
                        }).toList(),
                      ),
              )
            else if (_selectedSegment == _PlannerSegment.routes)
              Expanded(
                child: _RoutesListView(),
              )
            else
              const Expanded(
                child: SchedulesListView(),
              ),
            if (_isSelectionMode && _selectedSegment == _PlannerSegment.destinations)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Delete Selected (${_selectedIds.length})',
                      icon: Icons.delete_outline_rounded,
                      isDestructive: true,
                      onPressed: _deleteSelected,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutesListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(savedRoutesProvider);
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Could not load routes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textTertiary),
        ),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No saved routes yet.\nCreate a multi-stop trip and save it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textTertiary),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: routes.map((route) {
            final waypoints = route.waypoints;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        Icons.route_rounded,
                        color: context.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: AppTypography.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 14, color: context.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  '${waypoints.length} stop${waypoints.length == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                                ),
                                if (route.isFavorite) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(Icons.star_rounded, size: 14, color: context.warning),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      iconSize: 20,
                      icon: Icon(Icons.play_arrow_rounded, color: context.primary),
                      onPressed: () {
                        ref.read(activeTripProvider.notifier).startTripWithWaypoints(waypoints);
                        Navigator.pushNamed(context, '/active-trip');
                      },
                      tooltip: 'Start Trip',
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      iconSize: 20,
                      icon: Icon(
                        route.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: context.warning,
                      ),
                      onPressed: () {
                        final repo = ref.read(savedRouteRepositoryProvider);
                        repo.update(route.copyWith(isFavorite: !route.isFavorite));
                      },
                      tooltip: route.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      iconSize: 20,
                      icon: Icon(Icons.delete_outline_rounded, color: context.error),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Delete "${route.name}"?'),
                            content: const Text('This route will be permanently removed.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: context.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref.read(savedRouteRepositoryProvider).delete(route.id);
                        }
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DestinationTile extends ConsumerWidget {
  final Destination destination;
  final bool isActive;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;

  const _DestinationTile({
    required this.destination,
    this.isActive = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onLongPress,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${destination.name}"?'),
        content: const Text('This destination will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(destinationRepositoryProvider);
      await repo.delete(destination.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        onTap: isActive
            ? null
            : isSelectionMode
                ? onLongPress
                : () {
                    ref
                        .read(activeTripProvider.notifier)
                        .startTrip(destination);
                    Navigator.pushNamed(context, '/active-trip');
                  },
        onLongPress: isSelectionMode ? null : onLongPress,
        child: Row(
          children: [
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onLongPress(),
                activeColor: context.primary,
              ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: context.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: AppTypography.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      children: [
                        Icon(Icons.straighten,
                            size: 14, color: context.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${destination.alertRadius.round()}m',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                        ),
                        if (destination.isFavorite) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.star_rounded,
                              size: 14, color: context.warning),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: context.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Active',
                  style: AppTypography.caption.copyWith(
                    color: context.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (!isSelectionMode) ...{
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                icon: Icon(Icons.play_arrow_rounded,
                    color: context.primary),
                onPressed: () {
                  ref
                      .read(activeTripProvider.notifier)
                      .startTrip(destination);
                  Navigator.pushNamed(context, '/active-trip');
                },
                tooltip: 'Start Trip',
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                icon: Icon(
                  destination.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: context.warning,
                ),
                onPressed: () {
                  final repo = ref.read(destinationRepositoryProvider);
                  final updated = destination.copyWith(
                    isFavorite: !destination.isFavorite,
                  );
                  repo.update(updated);
                },
                tooltip: destination.isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                icon: Icon(Icons.edit_rounded,
                    color: context.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationSetupScreen(
                        existingDestination: destination,
                      ),
                    ),
                  );
                },
                tooltip: 'Edit',
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                icon: Icon(Icons.delete_outline_rounded,
                    color: context.error),
                onPressed: () => _confirmDelete(context, ref),
                tooltip: 'Delete',
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _RecentTripsSection extends ConsumerWidget {
  final List<TripRecord> trips;

  const _RecentTripsSection({required this.trips});

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trips.isEmpty) return const SizedBox.shrink();

    final displayTrips = trips.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Trips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...displayTrips.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _TripCard(
                trip: entry.value,
                relativeDate: _relativeDate(entry.value.startedAt),
                formattedDuration: _formatDuration(entry.value.duration),
              ).fadeSlideUp(delay: Duration(milliseconds: 60 * entry.key)),
            )),
      ],
    );
  }
}

class _TripCard extends ConsumerWidget {
  final TripRecord trip;
  final String relativeDate;
  final String formattedDuration;

  const _TripCard({
    required this.trip,
    required this.relativeDate,
    required this.formattedDuration,
  });

  IconData get _statusIcon {
    switch (trip.status) {
      case TripStatus.completed:
        return Icons.check_circle_rounded;
      case TripStatus.cancelled:
        return Icons.cancel_rounded;
      case TripStatus.alarmTriggered:
        return Icons.notifications_active_rounded;
      case TripStatus.monitoring:
        return Icons.timelapse_rounded;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (trip.status) {
      case TripStatus.completed:
        return context.success;
      case TripStatus.cancelled:
        return context.textTertiary;
      case TripStatus.alarmTriggered:
        return context.warning;
      case TripStatus.monitoring:
        return context.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceFormatted = GpsUtils.formatDistance(trip.totalDistance);
    final waypoints = trip.waypoints;
    final hasMultipleStops = waypoints.length > 1;

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        );
      },
      child: Row(
        children: [
          Hero(
            tag: 'trip-${trip.id}',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                _statusIcon,
                color: _statusColor(context),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destinationName,
                  style: AppTypography.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasMultipleStops
                      ? '${waypoints.length} stops · $distanceFormatted · $formattedDuration'
                      : '$distanceFormatted · $formattedDuration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                relativeDate,
                style: AppTypography.caption.copyWith(color: context.textTertiary),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  trip.status == TripStatus.alarmTriggered
                      ? 'Alarm'
                      : hasMultipleStops
                          ? '${waypoints.length} stops'
                          : trip.status.name[0].toUpperCase() + trip.status.name.substring(1),
                  style: AppTypography.caption.copyWith(
                    color: _statusColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
