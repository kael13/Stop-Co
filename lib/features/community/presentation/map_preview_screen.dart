import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/components/app_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

/// Full-screen map preview centered on a post's coordinates, opened from a
/// [CoordinateChip] tap. Reuses the existing OSM tile setup.
///
/// Optional: "Open in Google Maps" launches the external maps app via
/// `url_launcher` (already a project dep).
class MapPreviewScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? placeName;

  const MapPreviewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName ?? 'Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.tileUrlTemplate,
                userAgentPackageName: 'com.stopco.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: context.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
            ],
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: context.primary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '$latitude, $longitude',
                          style: AppTypography.secondary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Open in Google Maps',
                  isSecondary: true,
                  icon: Icons.map_outlined,
                  onPressed: () {
                    final uri = Uri.parse(
                      'geo:$latitude,$longitude?q=$latitude,$longitude',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}