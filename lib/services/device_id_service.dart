import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// デバイス固有のIDを管理するサービス
class DeviceIdService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  /// デバイス固有のIDを取得
  /// 初回呼び出し時に生成して保存し、以降は保存されたIDを返す
  static Future<String> getDeviceId() async {
    // キャッシュがあればそれを返す
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    // 保存されたIDがなければ新しく生成して保存
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    // キャッシュに保存
    _cachedDeviceId = deviceId;
    return deviceId;
  }
}
