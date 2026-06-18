import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../features/auth/data/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_rounded,
                    label: 'Saved Destinations',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.science_rounded,
                    label: 'Simulation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/simulation');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              onTap: () async {
                Navigator.pop(context);
                final auth = ref.read(authRepositoryProvider);
                await auth.signOut();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final UserSignedIn? user;

  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Guest';
    final email = user?.email ?? (user?.isAnonymous == true ? 'Guest Mode' : '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.electricBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.deepSlate,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.grey600,
        size: 24,
      ),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: AppColors.deepSlate,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}
