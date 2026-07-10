import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/poi.dart';

const _maxLabelWidth = 140.0;

List<Marker> buildPoiMarkers(
  List<Poi> pois,
  BuildContext context,
  void Function(Poi poi) onTap,
) {
  return pois.map((poi) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: poi.name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _maxLabelWidth);

    final labelWidth = (textPainter.width + 28).clamp(50.0, _maxLabelWidth);
    const emojiSize = 30.0;
    const labelHeight = 22.0;
    const gap = 2.0;
    final totalHeight = emojiSize + gap + labelHeight + 8;
    final totalWidth = labelWidth;

    return Marker(
      point: LatLng(poi.latitude, poi.longitude),
      width: totalWidth,
      height: totalHeight,
      child: GestureDetector(
        onTap: () => onTap(poi),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: emojiSize,
            height: emojiSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(poi.emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
          SizedBox(height: gap),
          Container(
            constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
            height: labelHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 12, color: Colors.black.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ],
      ),
        ),
    );
  }).toList();
}
