import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../trip/data/location_service.dart';
import '../../trip/data/trip_providers.dart';
import '../data/destination_model.dart';
import '../data/destination_repository.dart';
import '../data/geocoding_service.dart';

class DestinationSetupScreen extends ConsumerStatefulWidget {
  final Destination? existingDestination;

  const DestinationSetupScreen({super.key, this.existingDestination});

  @override
  ConsumerState<DestinationSetupScreen> createState() =>
      _DestinationSetupScreenState();
}

class _DestinationSetupScreenState
    extends ConsumerState<DestinationSetupScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _geocoding = GeocodingService();
  final _uuid = const Uuid();

  LatLng? _selectedLocation;
  LatLng? _userLocation;
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  double _alertRadius = AppConstants.defaultAlertRadius;
  bool _isSaving = false;
  bool _isStartingTrip = false;
  bool _isDeleting = false;
  String? _saveError;

  bool _isGettingLocation = false;
  bool _locationPermissionDenied = false;

  bool get _isEditing => widget.existingDestination != null;

  static const _initialCenter = LatLng(51.505, -0.09);
  static const _initialZoom = 13.0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDestination;
    if (existing != null) {
      _selectedLocation = LatLng(existing.latitude, existing.longitude);
      _nameController.text = existing.name;
      _alertRadius = existing.alertRadius;
    }
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationPermissionDenied = false;
    });

    final locationService = ref.read(locationServiceProvider);
    final hasPerm = await locationService.ensurePermissions();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _locationPermissionDenied = true;
        });
      }
      return;
    }

    try {
      final position = await locationService.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = latLng;
          _isGettingLocation = false;
        });
        if (!_isEditing) {
          _mapController.move(latLng, _initialZoom);
        } else {
          _mapController.move(
            _selectedLocation!,
            _initialZoom,
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await _geocoding.search(query);
      setState(() => _searchResults = results);
    } catch (_) {
      setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    final latLng = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = latLng;
      _searchResults = [];
      if (_nameController.text.isEmpty) {
        _nameController.text = result.displayName.split(',').first;
      }
    });
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  void _onMapTap(TapPosition tap, LatLng latLng) {
    setState(() => _selectedLocation = latLng);
  }

  Future<void> _saveDestination() async {
    if (_selectedLocation == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'Please enter a destination name');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final repo = ref.read(destinationRepositoryProvider);

      if (_isEditing) {
        final updated = widget.existingDestination!.copyWith(
          name: name,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          alertRadius: _alertRadius,
        );
        await repo
            .update(updated)
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception('Save timed out. Check your connection.');
        });
      } else {
        final destination = Destination(
          id: _uuid.v4(),
          name: name,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          alertRadius: _alertRadius,
          createdAt: DateTime.now(),
        );
        await repo
            .save(destination)
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception('Save timed out. Check your connection.');
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndStartTrip() async {
    if (_selectedLocation == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'Please enter a destination name');
      return;
    }

    setState(() {
      _isStartingTrip = true;
      _saveError = null;
    });

    try {
      final repo = ref.read(destinationRepositoryProvider);
      final destination = Destination(
        id: _uuid.v4(),
        name: name,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        alertRadius: _alertRadius,
        createdAt: DateTime.now(),
      );
      await repo
          .save(destination)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Save timed out. Check your connection.');
      });

      if (mounted) {
        ref.read(activeTripProvider.notifier).startTrip(destination);
        Navigator.pushReplacementNamed(context, '/active-trip');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isStartingTrip = false);
    }
  }

  Future<void> _deleteDestination() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${widget.existingDestination!.name}"?'),
        content: const Text(
          'This destination will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final repo = ref.read(destinationRepositoryProvider);
      await repo
          .delete(widget.existingDestination!.id)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Delete timed out. Check your connection.');
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _isSaving || _isStartingTrip || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Destination' : 'Set Destination'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              onPressed: isDisabled ? null : _deleteDestination,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ??
                        _userLocation ??
                        _initialCenter,
                    initialZoom: _initialZoom,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.stopco.app',
                    ),
                    if (_userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.electricBlue,
                                  width: 2.5,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.electricBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.electricBlue,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    SimpleAttributionWidget(
                      source: const Text('© OpenStreetMap contributors'),
                      alignment: Alignment.bottomRight,
                    ),
                  ],
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Column(
                    children: [
                      AppInput(
                        hint: 'Search for a place...',
                        controller: _searchController,
                        prefixIcon: Icons.search_rounded,
                        suffix: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search_rounded),
                                onPressed:
                                    isDisabled ? null : _searchLocation,
                              ),
                        onSubmitted: _searchLocation,
                      ),
                      if (_searchResults.isNotEmpty)
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: _searchResults.map((result) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  result.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.secondary,
                                ),
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: AppColors.grey400,
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            }).toList(),
                          ),
                        ),
                      if (_locationPermissionDenied)
                        AppCard(
                          color:
                              AppColors.warning.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Location permission denied. Tap here to enable in settings.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.electricBlue,
                    onPressed: _isGettingLocation
                        ? null
                        : _getUserLocation,
                    child: _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          _BottomPanel(
            selectedLocation: _selectedLocation,
            radius: _alertRadius,
            nameController: _nameController,
            error: _saveError,
            isEditing: _isEditing,
            onRadiusChanged: (r) => setState(() => _alertRadius = r),
            onSave: isDisabled ? null : _saveDestination,
            onSaveAndStart: isDisabled ? null : _saveAndStartTrip,
            isSaving: _isSaving,
            isStartingTrip: _isStartingTrip,
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final LatLng? selectedLocation;
  final double radius;
  final TextEditingController nameController;
  final String? error;
  final bool isEditing;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndStart;
  final bool isSaving;
  final bool isStartingTrip;

  const _BottomPanel({
    this.selectedLocation,
    required this.radius,
    required this.nameController,
    this.error,
    this.isEditing = false,
    required this.onRadiusChanged,
    required this.onSave,
    this.onSaveAndStart,
    required this.isSaving,
    this.isStartingTrip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            hint: 'Destination name',
            controller: nameController,
            prefixIcon: Icons.edit_location_alt_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Text(
                'Alert Radius',
                style: AppTypography.secondary,
              ),
              const Spacer(),
              ...AppConstants.alertRadiusOptions.map((r) {
                final selected = r == radius;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(
                      '${r.round()}m',
                      style: AppTypography.caption.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => onRadiusChanged(r),
                    selectedColor: AppColors.electricBlue,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.white : null,
                    ),
                    backgroundColor: AppColors.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      side: BorderSide.none,
                    ),
                  ),
                );
              }),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error!,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (selectedLocation != null && !isEditing) ...[
            AppButton(
              label: 'Start Trip',
              icon: Icons.navigation_rounded,
              onPressed: onSaveAndStart,
              isLoading: isStartingTrip,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSave,
                child: Text(
                  'Save Only',
                  style: AppTypography.secondary.copyWith(
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ),
          ] else
            AppButton(
              label: selectedLocation != null
                  ? 'Update Destination'
                  : 'Tap map to select location',
              onPressed: onSave,
              isLoading: isSaving,
            ),
        ],
      ),
    );
  }
}
