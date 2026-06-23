import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/components/app_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../destination/data/geocoding_service.dart';
import '../../trip/data/location_service.dart';
import '../data/community_providers.dart';

/// Post creation screen: description + up to 3 images + map-tap coordinates.
///
/// Flow:
/// 1. User writes description (max 500 chars)
/// 2. Optionally picks up to 3 images via [ImagePicker] (gallery, no permissions)
/// 3. Taps the map to set coordinates (or taps "Use my current location")
/// 4. Tap submit → uploads images to Storage → creates Firestore post doc
/// 5. Returns to feed, which live-updates with the new post
class PostComposerScreen extends ConsumerStatefulWidget {
  const PostComposerScreen({super.key});

  @override
  ConsumerState<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends ConsumerState<PostComposerScreen> {
  final _descriptionController = TextEditingController();
  final List<XFile> _pickedImages = [];
  final _imagePicker = ImagePicker();

  LatLng? _coords;
  String? _placeName;
  bool _isUploading = false;
  bool _reverseGeocoding = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _descriptionController.text.trim().isNotEmpty;

  Future<void> _pickImages() async {
    if (_pickedImages.length >= 3) return;
    try {
      final photos = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        limit: 3 - _pickedImages.length,
      );
      if (photos.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(photos.take(3 - _pickedImages.length));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image pick failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _reverseGeocoding = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getCurrentPosition();
      if (pos != null) {
        _setCoords(LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reverseGeocoding = false);
    }
  }

  void _setCoords(LatLng point) {
    setState(() {
      _coords = point;
      _placeName = null;
    });
    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _reverseGeocoding = true);
    try {
      final geocoding = GeocodingService();
      final name = await geocoding.reverseGeocode(point.latitude, point.longitude);
      if (mounted) {
        setState(() => _placeName = name);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reverseGeocoding = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final user = ref.read(currentCommunityUserProvider).valueOrNull;
    if (user == null || !user.canWriteCommunity) return;

    setState(() => _isUploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final postId = repo.generatePostId();

      // Upload images to Storage — skip individual failures so one bad upload
      // doesn't prevent the post from being created
      final imageURLs = <String>[];
      final imagePaths = <String>[];
      var uploadFailures = 0;
      for (var i = 0; i < _pickedImages.length; i++) {
        try {
          final xfile = _pickedImages[i];
          final bytes = await xfile.readAsBytes();
          final ext = (xfile.name.split('.').lastOrNull ?? 'jpg').toLowerCase();
          final result = await repo.uploadPostImage(
            postId,
            bytes,
            index: i,
            ext: (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp')
                ? ext
                : 'jpg',
          );
          if (result != null) {
            imageURLs.add(result.url);
            imagePaths.add(result.path);
          }
        } catch (e) {
          uploadFailures++;
        }
      }

      // Create the Firestore post doc (coords optional — 0,0 if not set)
      await ref.read(createPostActionProvider(
        CreatePostArgs(
          author: user,
          description: _descriptionController.text.trim(),
          latitude: _coords?.latitude ?? 0,
          longitude: _coords?.longitude ?? 0,
          placeName: _placeName,
          imageURLs: imageURLs,
          imagePaths: imagePaths,
          postId: postId,
        ),
      ).future);

      // Invalidate feed so it refreshes
      ref.invalidate(communityFeedProvider);

      if (mounted) {
        final msg = uploadFailures > 0
            ? 'Post created ($uploadFailures image(s) failed to upload)'
            : 'Post created!';
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description
            _SectionLabel(icon: Icons.edit_outlined, text: 'Description'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What\'s happening?',
                border: const OutlineInputBorder(),
                counterText: '${_descriptionController.text.length}/500',
              ),
              onChanged: (_) => setState(() {}),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Images
            _SectionLabel(
              icon: Icons.image_outlined,
              text: 'Images (${_pickedImages.length}/3)',
            ),
            const SizedBox(height: AppSpacing.xs),
            _ImageSlotRow(
              images: _pickedImages,
              onPick: _pickImages,
              onRemove: _removeImage,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Location (optional)
            _SectionLabel(
              icon: Icons.location_on_outlined,
              text: 'Location (optional)',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the map to add coordinates',
              style: AppTypography.secondary.copyWith(color: context.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MapPicker(
              coords: _coords,
              placeName: _placeName,
              reverseGeocoding: _reverseGeocoding,
              onTap: _setCoords,
              onUseCurrentLocation: _useCurrentLocation,
            ),
          ],
        ),
      ),
      floatingActionButton: _isUploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _canSubmit ? _submit : null,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Post'),
              backgroundColor: _canSubmit ? null : context.outlineVariant,
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: AppTypography.secondary.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class _ImageSlotRow extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  const _ImageSlotRow({
    required this.images,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        if (index < images.length) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? AppSpacing.xs : 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: _XFileThumbnail(xfile: images[index]),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Empty slot
        final isAddSlot = index == images.length;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? AppSpacing.xs : 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Material(
                color: isAddSlot
                    ? context.primary.withValues(alpha: 0.08)
                    : context.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: isAddSlot
                    ? InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        onTap: onPick,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 28, color: context.primary),
                            const SizedBox(height: 4),
                            Text('Add',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: context.primary,
                                )),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MapPicker extends StatelessWidget {
  final LatLng? coords;
  final String? placeName;
  final bool reverseGeocoding;
  final ValueChanged<LatLng> onTap;
  final VoidCallback onUseCurrentLocation;
  const _MapPicker({
    required this.coords,
    required this.placeName,
    required this.reverseGeocoding,
    required this.onTap,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: coords ?? const LatLng(14.5912, 120.9789),
                initialZoom: 13,
                onTap: (_, point) => onTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.tileUrlTemplate,
                  userAgentPackageName: 'com.stopco.app',
                ),
                if (coords != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: coords!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: context.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors',
                        style: GoogleFonts.inter(fontSize: 9))),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Use my location',
                isTonal: true,
                icon: Icons.my_location_rounded,
                isLoading: reverseGeocoding,
                onPressed: onUseCurrentLocation,
              ),
            ),
          ],
        ),
        if (coords != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 18, color: context.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: reverseGeocoding && placeName == null
                      ? Text('Looking up address...',
                          style: AppTypography.secondary.copyWith(
                            color: context.textTertiary,
                            fontStyle: FontStyle.italic,
                          ))
                      : Text(
                          placeName ??
                              '${coords!.latitude.toStringAsFixed(4)}, ${coords!.longitude.toStringAsFixed(4)}',
                          style: AppTypography.secondary.copyWith(
                            color: context.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
/// Loads image bytes from an [XFile] once and caches them. Handles `content://`
/// URIs from the Android Photo Picker (which can't be read via `File()`).
class _XFileThumbnail extends StatefulWidget {
  final XFile xfile;
  const _XFileThumbnail({required this.xfile});

  @override
  State<_XFileThumbnail> createState() => _XFileThumbnailState();
}

class _XFileThumbnailState extends State<_XFileThumbnail> {
  Uint8List? _bytes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    widget.xfile.readAsBytes().then((b) {
      if (mounted) setState(() => _bytes = b);
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: const Icon(Icons.broken_image_outlined),
      );
    }
    if (_bytes == null) {
      return Container(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
