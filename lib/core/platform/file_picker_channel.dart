import 'package:flutter/services.dart';

class FilePickerChannel {
  static const _channelName = 'com.stopco.app/file_picker';
  static final _channel = const MethodChannel(_channelName);

  static Future<String?> pickAudioFile() async {
    try {
      return await _channel.invokeMethod<String>('pickAudioFile');
    } on MissingPluginException {
      return null;
    }
  }
}
