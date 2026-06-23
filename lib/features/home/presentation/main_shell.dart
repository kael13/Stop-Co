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
import '../../auth/data/auth_providers.dart';
import '../../community/presentation/community_feed_tab.dart';
import '../../destination/data/destination_model.dart';
import '../../destination/data/destination_providers.dart';
import '../../destination/data/destination_repository.dart';
import '../../destination/presentation/destination_setup_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../simulation/presentation/simulation_screen.dart';
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
  int _currentIndex = 0;
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
    _TabItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on_rounded, label: 'Saved'),
    _TabItem(icon: Icons.science_outlined, activeIcon: Icons.science_rounded, label: 'Simulate'),
    _TabItem(icon: Icons.groups_2_outlined, activeIcon: Icons.groups_2_rounded, label: 'Community'),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  final _pages = const <Widget>[
    _HomeTab(),
    _DestinationsTab(),
    SimulationScreen(),
    CommunityFeedTab(),
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
          border: Border(
            top: BorderSide(
              color: context.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              top: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final selected = _currentIndex == index;
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.selected ? context.primary : context.textTertiary,
                ),
              ),
            ],
          ),
        ),
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
    final authState = ref.watch(authStateProvider);
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeTabHeader(authState: authState.valueOrNull)
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

class _HomeTabHeader extends StatelessWidget {
  final UserSignedIn? authState;
  const _HomeTabHeader({this.authState});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
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
          if (authState?.displayName != null)
            Text(
              'Hi, ${authState!.displayName}',
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
    final distance = trip.currentDistance ?? 0;
    final distanceFormatted = GpsUtils.formatDistance(distance);
    final progress = distance > 0 && trip.destination.alertRadius > 0
        ? (distance / trip.destination.alertRadius).clamp(0.0, 1.0)
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
              trip.destination.name,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: context.textPrimary),
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

class _DestinationsTab extends ConsumerStatefulWidget {
  const _DestinationsTab();

  @override
  ConsumerState<_DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends ConsumerState<_DestinationsTab> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

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
                    'Saved Destinations',
                    style: AppTypography.largeTitle,
                  ),
                  if (_isSelectionMode)
                    TextButton(
                      onPressed: _exitSelectionMode,
                      child: const Text('Cancel'),
                    )
                  else
                    Text(
                      '${destinations.length} saved',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textTertiary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                        final isActive = dest.id == activeTrip?.destination.id;
                        return _DestinationTile(
                          destination: dest,
                          isActive: isActive,
                          isSelected: _selectedIds.contains(dest.id),
                          isSelectionMode: _isSelectionMode,
                          onLongPress: () => _toggleSelection(dest.id),
                        );
                      }).toList(),
                    ),
            ),
            if (_isSelectionMode)
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
        if (trips.length > 5) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Future: navigate to full trips list
              },
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: Text(
                'View all ${trips.length} trips',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
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
                  '$distanceFormatted · $formattedDuration',
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
