import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _nicknameKey = 'profile_nickname';
const _uidKey = 'profile_uid';

class LocalProfile {
  final String uid;
  final String nickname;

  const LocalProfile({required this.uid, required this.nickname});
}

Future<String?> getNickname() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_nicknameKey);
}

Future<LocalProfile> createProfile(String nickname) async {
  final prefs = await SharedPreferences.getInstance();
  final uid = const Uuid().v4();
  await prefs.setString(_uidKey, uid);
  await prefs.setString(_nicknameKey, nickname);
  return LocalProfile(uid: uid, nickname: nickname);
}

Future<void> updateNickname(String nickname) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_nicknameKey, nickname);
}
