import 'dart:async';
import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_input.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../scheduled_trip/presentation/schedule_trip_form_screen.dart';
import '../../trip/data/location_service.dart';
import '../../trip/data/trip_providers.dart';
import '../../trip/data/waypoint.dart';
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
  final _mapKey = GlobalKey();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _geocoding = GeocodingService();
  final _uuid = const Uuid();
  Timer? _searchDebounce;
  String _lastSearchQuery = '';

  LatLng? _userLocation;
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _isStartingTrip = false;
  bool _isDeleting = false;
  String? _saveError;

  List<Waypoint> _waypoints = [];

  double _editRadius = AppConstants.defaultAlertRadius;
  String _editName = '';
  int? _editingIndex;

  bool _multiMode = false;

  int? _draggingIndex;

  bool get _isEditing => widget.existingDestination != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.existingDestination!;
      _waypoints = [Waypoint.fromDestination(d, 0)];
      _editName = d.name;
      _editRadius = d.alertRadius;
      _nameController.text = _editName;
    } else {
      _getUserLocation();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final hasPerm = await locationService.ensurePermissions();
    if (!hasPerm) {
      if (mounted) {
        // permission denied
      }
    } else {
      final pos = await locationService.getCurrentPosition();
      if (mounted && pos != null) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_userLocation!, 13);
      }
    }
  }

  void _onMapTap(LatLng latLng) {
    if (_editingIndex != null) {
      _showEditSheet(_editingIndex!, latLng: latLng);
      return;
    }
    if (!_multiMode && _waypoints.isNotEmpty) {
      setState(() {
        _waypoints[0] = _waypoints[0].copyWith(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        );
        _editName = _waypoints[0].name;
      });
      return;
    }
    if (_waypoints.length >= AppConstants.maxWaypoints) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 stops allowed')),
        );
      }
      return;
    }
    final waypoint = Waypoint(
      id: _uuid.v4(),
      name: 'Stop ${_waypoints.length + 1}',
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      alertRadius: AppConstants.defaultAlertRadius,
      orderIndex: _waypoints.length,
    );
    setState(() {
      _waypoints.add(waypoint);
    });
    if (_waypoints.length == 1) {
      _editName = waypoint.name;
      _editRadius = waypoint.alertRadius;
      _nameController.text = _editName;
    }
  }

  void _editWaypointName(int index, String name) {
    setState(() {
      _waypoints[index] = _waypoints[index].copyWith(name: name);
      if (index == 0 && !_waypoints[index].name.startsWith('Stop ')) {
        _editName = name;
      }
    });
  }

  void _editWaypointRadius(int index, double radius) {
    setState(() {
      _waypoints[index] = _waypoints[index].copyWith(alertRadius: radius);
      if (index == 0) _editRadius = radius;
    });
  }

  void _removeWaypoint(int index) {
    if (_waypoints.length <= 1) return;
    setState(() {
      _waypoints.removeAt(index);
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(orderIndex: i);
      }
    });
  }

  void _reorderWaypoint(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _waypoints.removeAt(oldIndex);
      _waypoints.insert(newIndex, item);
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(orderIndex: i);
      }
    });
  }

  bool get _hasValidWaypoints =>
      _waypoints.isNotEmpty && _waypoints.every((w) => w.name.trim().isNotEmpty);

  Future<void> _saveAndStartTrip() async {
    if (!_hasValidWaypoints) {
      setState(() => _saveError = 'Please name each stop');
      return;
    }
    setState(() => _isStartingTrip = true);

    if (_waypoints.length == 1) {
      final d = widget.existingDestination;
      if (d != null) {
        final updated = d.copyWith(
          name: _waypoints.first.name,
          alertRadius: _waypoints.first.alertRadius,
        );
        await ref.read(destinationRepositoryProvider).update(updated);
      }
    }

    ref.read(activeTripProvider.notifier).startTripWithWaypoints(_waypoints);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/active-trip');
    }
  }

  Future<void> _saveDestination() async {
    if (!_hasValidWaypoints) {
      setState(() => _saveError = 'Please name the destination');
      return;
    }
    final wp = _waypoints.first;
    setState(() => _isSaving = true);
    final repo = ref.read(destinationRepositoryProvider);

    if (widget.existingDestination != null) {
      final updated = widget.existingDestination!.copyWith(
        name: wp.name,
        latitude: wp.latitude,
        longitude: wp.longitude,
        alertRadius: wp.alertRadius,
      );
      await repo.update(updated);
    } else {
      final dest = Destination(
        id: wp.id,
        name: wp.name,
        latitude: wp.latitude,
        longitude: wp.longitude,
        alertRadius: wp.alertRadius,
        createdAt: DateTime.now(),
      );
      await repo.save(dest);
    }
    if (mounted) Navigator.pop(context, true);
  }

  void _scheduleTrip() {
    if (_waypoints.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleTripFormScreen(waypoints: _waypoints),
      ),
    );
  }

  Future<void> _deleteDestination() async {
    if (widget.existingDestination == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this destination?'),
        content: const Text('This destination will be permanently removed.'),
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
      setState(() => _isDeleting = true);
      await ref.read(destinationRepositoryProvider).delete(
        widget.existingDestination!.id,
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showEditSheet(int index, {LatLng? latLng}) {
    final wp = _waypoints[index];
    _editName = wp.name;
    _editRadius = wp.alertRadius;
    _editingIndex = index;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _WaypointEditSheet(
        initialName: wp.name,
        initialRadius: wp.alertRadius,
        onSave: (name, radius) {
          _editWaypointName(index, name);
          _editWaypointRadius(index, radius);
          Navigator.pop(ctx);
          setState(() => _editingIndex = null);
        },
        latLng: latLng,
      ),
    );
  }

  void _onLongPressStart(int index) {
    setState(() => _draggingIndex = index);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingIndex == null) return;
    final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final latLng = _mapController.camera.pointToLatLng(
      Point(localPos.dx, localPos.dy),
    );
    setState(() {
      _waypoints[_draggingIndex!] = _waypoints[_draggingIndex!].copyWith(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    });
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => _draggingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          RepaintBoundary(
            child: FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _isEditing && widget.existingDestination != null
                  ? LatLng(
                      widget.existingDestination!.latitude,
                      widget.existingDestination!.longitude,
                    )
                  : (_userLocation ?? const LatLng(14.5995, 120.9842)),
              initialZoom: 13,
              onTap: (_, latLng) => _onMapTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.tileUrlTemplate,
                userAgentPackageName: 'com.stopco.app',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ..._waypoints.asMap().entries.map((entry) {
                    final i = entry.key;
                    final wp = entry.value;
                    final isFirst = i == 0;
                    final number = i + 1;
                    return Marker(
                      point: LatLng(wp.latitude, wp.longitude),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showEditSheet(i),
                        onLongPressStart: (_) => _onLongPressStart(i),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: _draggingIndex == i ? 10 : 4,
                                    spreadRadius: _draggingIndex == i ? 3 : 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _draggingIndex == i
                                  ? const Icon(Icons.drag_indicator_rounded, color: Colors.white54, size: 24)
                                  : null,
                            ),
                            if (_waypoints.length > 1)
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? (Theme.of(context).colorScheme.primary)
                                      : Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isFirst
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                                          : Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$number',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.location_on_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 30,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Column(
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _isSearching = false;
                      _lastSearchQuery = '';
                    });
                  },
                ),
                if (_draggingIndex != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 16,
                            color: context.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Drag it to your preferred location',
                              style: AppTypography.secondary.copyWith(
                                color: context.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isSearching && _searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Searching…',
                                style: AppTypography.secondary),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_searchResults.isNotEmpty)
                  _SearchResultsDropdown(
                    results: _searchResults,
                    onSelect: _selectSearchResult,
                  ),
              ],
            ),
          ),

          if (_draggingIndex != null)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Container(color: Colors.transparent),
              ),
            ),
          if (_userLocation != null)
            Positioned(
              bottom: 260,
              right: AppSpacing.sm,
              child: FloatingActionButton.small(
                heroTag: 'my-location',
                onPressed: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 15);
                  }
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
      bottomSheet: _isEditing
          ? _buildEditBottomSheet()
          : _buildPlannerBottomSheet(),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _lastSearchQuery = query;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _geocoding.search(
        query,
        nearLat: _userLocation?.latitude,
        nearLon: _userLocation?.longitude,
      );
      if (mounted && _lastSearchQuery == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(GeocodingResult result) {
    final latLng = LatLng(result.latitude, result.longitude);
    if (!_multiMode && _waypoints.isNotEmpty) {
      setState(() {
        _waypoints[0] = _waypoints[0].copyWith(
          latitude: result.latitude,
          longitude: result.longitude,
          name: result.displayName,
        );
        _editName = result.displayName;
        _nameController.text = _editName;
        _searchResults = [];
        _searchController.clear();
      });
      _mapController.move(latLng, 15);
      return;
    }
    if (_waypoints.length >= AppConstants.maxWaypoints) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 stops allowed')),
        );
      }
      return;
    }
    final waypoint = Waypoint(
      id: _uuid.v4(),
      name: result.displayName,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      alertRadius: AppConstants.defaultAlertRadius,
      orderIndex: _waypoints.length,
    );
    setState(() {
      _waypoints.add(waypoint);
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(latLng, 15);
    if (_waypoints.length == 1) {
      _editName = waypoint.name;
      _nameController.text = _editName;
    }
  }

  void _enterMultiMode() {
    setState(() => _multiMode = true);
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 13);
    }
  }

  Widget _buildPlannerBottomSheet() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.40 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: _waypoints.isEmpty
          ? _buildEmptyPlanner()
          : (_waypoints.length == 1 && !_multiMode)
              ? _buildSingleStopPanel()
              : _buildWaypointList(),
      ),
    );
  }

  Widget _buildSingleStopPanel() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to?',
            style: AppTypography.sectionHeader.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppInput(
            controller: _nameController,
            hint: 'Destination name',
            prefixIcon: Icons.edit_location_rounded,
            onChanged: (v) {
              setState(() => _editName = v);
              _editWaypointName(0, v);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Alert Radius',
            style: AppTypography.caption.copyWith(color: context.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.xs,
            children: AppConstants.alertRadiusOptions.map((r) {
              final selected = _editRadius == r;
              return ChoiceChip(
                label: Text('${r.round()}m'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _editRadius = r);
                  _editWaypointRadius(0, r);
                },
                selectedColor: context.primary.withValues(alpha: 0.15),
              );
            }).toList(),
          ),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                _saveError!,
                style: AppTypography.caption.copyWith(color: context.error),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _saveDestination,
                  child: const Text('Save Only'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Start Trip',
                  icon: Icons.near_me_rounded,
                  isLoading: _isStartingTrip,
                  onPressed: _saveAndStartTrip,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              onPressed: _scheduleTrip,
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Schedule trip'),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _enterMultiMode,
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Add another stop'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlanner() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 28, color: context.textTertiary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the map to add your first stop',
            style: AppTypography.secondary.copyWith(color: context.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Or search above to find a location',
            style: AppTypography.caption.copyWith(color: context.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointList() {
    final remaining = AppConstants.maxWaypoints - _waypoints.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_waypoints.length}/${AppConstants.maxWaypoints} stops',
                      style: AppTypography.secondary.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (remaining > 0)
                    TextButton.icon(
                      onPressed: () {
                        if (_userLocation != null) {
                          _mapController.move(_userLocation!, 13);
                        }
                      },
                      icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                      label: const Text('+ Add'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    Text(
                      'Max (5)',
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _waypoints.length / AppConstants.maxWaypoints,
                  minHeight: 3,
                  backgroundColor: context.outlineVariant,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: _waypoints.length,
            onReorderItem: _reorderWaypoint,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemBuilder: (context, index) {
              final wp = _waypoints[index];
              final number = index + 1;
              return _WaypointRow(
                key: ValueKey(wp.id),
                number: number,
                name: wp.name,
                radius: wp.alertRadius,
                isFirst: index == 0,
                canRemove: _waypoints.length > 1,
                onEdit: () => _showEditSheet(index),
                onRemove: () => _removeWaypoint(index),
                onChangeName: (name) => _editWaypointName(index, name),
              );
            },
          ),
        ),
        if (_saveError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              _saveError!,
              style: AppTypography.caption.copyWith(color: context.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.xxs, AppSpacing.sm, AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _saveDestination,
                  child: const Text('Save Only'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: _waypoints.length == 1
                      ? 'Start Trip'
                      : 'Start Trip (${_waypoints.length} stops)',
                  icon: Icons.near_me_rounded,
                  isLoading: _isStartingTrip,
                  onPressed: _saveAndStartTrip,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: _scheduleTrip,
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('Schedule trip'),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBottomSheet() {
    if (widget.existingDestination == null) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit',
                  style: AppTypography.sectionHeader.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppInput(
                  controller: _nameController..text = _editName,
                  hint: 'Destination name',
                  prefixIcon: Icons.edit_location_rounded,
                  onChanged: (v) {
                    setState(() => _editName = v);
                    _editWaypointName(0, v);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Alert Radius',
                  style: AppTypography.caption.copyWith(color: context.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: AppConstants.alertRadiusOptions.map((r) {
                    final selected = _editRadius == r;
                    return ChoiceChip(
                      label: Text('${r.round()}m'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _editRadius = r);
                        _editWaypointRadius(0, r);
                      },
                      selectedColor: context.primary.withValues(alpha: 0.15),
                    );
                  }).toList(),
                ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      _saveError!,
                      style: AppTypography.caption.copyWith(color: context.error),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Update',
                    isLoading: _isSaving,
                    onPressed: _saveDestination,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: context.error),
                  onPressed: _isDeleting ? null : _deleteDestination,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      hint: 'Search location',
      prefixIcon: Icons.search_rounded,
      suffix: controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: onClear,
            )
          : null,
      onChanged: onChanged,
    );
  }
}

class _SearchResultsDropdown extends StatelessWidget {
  final List<GeocodingResult> results;
  final ValueChanged<GeocodingResult> onSelect;

  const _SearchResultsDropdown({
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: AppCard(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: context.outlineVariant),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              dense: true,
              leading: Icon(Icons.location_on_rounded, size: 16, color: context.primary),
              title: Text(
                result.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.secondary,
              ),
              onTap: () => onSelect(result              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _WaypointRow extends StatelessWidget {
  final int number;
  final String name;
  final double radius;
  final bool isFirst;
  final bool canRemove;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final ValueChanged<String> onChangeName;

  const _WaypointRow({
    super.key,
    required this.number,
    required this.name,
    required this.radius,
    required this.isFirst,
    required this.canRemove,
    required this.onEdit,
    required this.onRemove,
    required this.onChangeName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isFirst
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isFirst
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.secondary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${radius.round()}m radius',
                  style: AppTypography.caption.copyWith(
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 16, color: context.primary),
            onPressed: onEdit,
            tooltip: 'Edit',
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          if (canRemove)
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, size: 16, color: context.error),
              onPressed: onRemove,
              tooltip: 'Remove',
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _WaypointEditSheet extends StatefulWidget {
  final String initialName;
  final double initialRadius;
  final void Function(String name, double radius) onSave;
  final LatLng? latLng;

  const _WaypointEditSheet({
    required this.initialName,
    required this.initialRadius,
    required this.onSave,
    this.latLng,
  });

  @override
  State<_WaypointEditSheet> createState() => _WaypointEditSheetState();
}

class _WaypointEditSheetState extends State<_WaypointEditSheet> {
  late TextEditingController _nameController;
  late double _selectedRadius;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedRadius = widget.initialRadius;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Edit Stop',
              style: AppTypography.title.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppInput(
              controller: _nameController,
              hint: 'Stop name',
              prefixIcon: Icons.edit_location_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Alert Radius',
              style: AppTypography.caption.copyWith(color: context.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: AppConstants.alertRadiusOptions.map((r) {
                final selected = _selectedRadius == r;
                return ChoiceChip(
                  label: Text('${r.round()}m'),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedRadius = r),
                  selectedColor: context.primary.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save',
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  widget.onSave(name, _selectedRadius);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
