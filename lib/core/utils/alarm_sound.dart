class AlarmSoundHelper {
  static const _separator = '||';

  static String? getInternalPath(String? stored) {
    if (stored == null) return null;
    if (stored.contains(_separator)) return stored.split(_separator).first;
    if (!stored.startsWith('content://')) return stored;
    return null;
  }

  static String? getNotificationUri(String? stored) {
    if (stored == null) return null;
    if (stored.contains(_separator)) return stored.split(_separator).last;
    if (stored.startsWith('content://')) return stored;
    return null;
  }
}
