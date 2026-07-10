import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_service.dart';

final nicknameProvider = FutureProvider<String?>((ref) async {
  return getNickname();
});

final createProfileActionProvider = FutureProvider.family<void, String>(
  (ref, nickname) async {
    await createProfile(nickname);
    ref.invalidate(nicknameProvider);
  },
);

final updateNicknameActionProvider = FutureProvider.family<void, String>(
  (ref, nickname) async {
    await updateNickname(nickname);
    ref.invalidate(nicknameProvider);
  },
);
