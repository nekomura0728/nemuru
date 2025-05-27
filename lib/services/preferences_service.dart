import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PreferencesService extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  // Keys for SharedPreferences
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _selectedCharacterIdKey = 'selected_character_id';
  static const String _isPremiumKey = 'is_premium';
  static const String _deviceIdKey = 'device_id';
  
  // サブスクリプション関連のキー
  static const String _todayConversationCountKey = 'today_conversation_count';
  static const String _monthlyConversationCountKey = 'monthly_conversation_count';
  static const String _lastConversationDateKey = 'last_conversation_date';
  static const String _lastMonthlyResetDateKey = 'last_monthly_reset_date';
  
  // Default values
  bool _onboardingCompleted = false;
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;
  int _selectedCharacterId = 0; // デフォルトは左上の犬アイコン
  bool _isPremium = false; // プレミアム機能のフラグ
  String _deviceId = ''; // デバイスID
  
  // サブスクリプション関連の値
  int _todayConversationCount = 0;
  int _monthlyConversationCount = 0;
  DateTime? _lastConversationDate;
  DateTime? _lastMonthlyResetDate;
  
  // Getters
  bool get onboardingCompleted => _onboardingCompleted;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isDarkMode => _isDarkMode;
  int get selectedCharacterId => _selectedCharacterId;
  bool get isPremium => _isPremium;
  String get deviceId => _deviceId;
  
  // サブスクリプション関連のゲッター
  int get todayConversationCount => _todayConversationCount;
  int get monthlyConversationCount => _monthlyConversationCount;
  DateTime? get lastConversationDate => _lastConversationDate;
  DateTime? get lastMonthlyResetDate => _lastMonthlyResetDate;
  
  // Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
  }
  
  // Load saved preferences
  void _loadPreferences() {
    _onboardingCompleted = _prefs.getBool(_onboardingCompletedKey) ?? false;
    _notificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    _isDarkMode = _prefs.getBool(_isDarkModeKey) ?? false;
    _selectedCharacterId = _prefs.getInt(_selectedCharacterIdKey) ?? 0;
    _isPremium = _prefs.getBool(_isPremiumKey) ?? false;
    
    // デバイスIDをロードまたは生成
    _deviceId = _prefs.getString(_deviceIdKey) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = const Uuid().v4();
      _prefs.setString(_deviceIdKey, _deviceId);
    }
    
    // サブスクリプション関連の設定をロード
    _todayConversationCount = _prefs.getInt(_todayConversationCountKey) ?? 0;
    _monthlyConversationCount = _prefs.getInt(_monthlyConversationCountKey) ?? 0;
    
    final lastConvDateStr = _prefs.getString(_lastConversationDateKey);
    if (lastConvDateStr != null) {
      _lastConversationDate = DateTime.parse(lastConvDateStr);
    }
    
    final lastMonthlyResetStr = _prefs.getString(_lastMonthlyResetDateKey);
    if (lastMonthlyResetStr != null) {
      _lastMonthlyResetDate = DateTime.parse(lastMonthlyResetStr);
    }
    
    notifyListeners();
  }
  
  // Set onboarding completed
  Future<void> setOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
    await _prefs.setBool(_onboardingCompletedKey, completed);
    notifyListeners();
  }
  
  // Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }
  
  // Toggle dark mode
  Future<void> setIsDarkMode(bool darkMode) async {
    _isDarkMode = darkMode;
    await _prefs.setBool(_isDarkModeKey, darkMode);
    notifyListeners();
  }
  
  // Save selected character ID
  Future<void> saveSelectedCharacterId(int characterId) async {
    _selectedCharacterId = characterId;
    await _prefs.setInt(_selectedCharacterIdKey, characterId);
    notifyListeners();
  }
  
  // Set premium status
  Future<void> setPremium(bool isPremium) async {
    _isPremium = isPremium;
    await _prefs.setBool(_isPremiumKey, isPremium);
    notifyListeners();
  }
  
  // デバイスIDを設定（主にテスト用）
  Future<void> setDeviceId(String deviceId) async {
    _deviceId = deviceId;
    await _prefs.setString(_deviceIdKey, deviceId);
    notifyListeners();
  }
  
  // サブスクリプション関連のメソッド
  Future<void> saveTodayConversationCount(int count) async {
    _todayConversationCount = count;
    await _prefs.setInt(_todayConversationCountKey, count);
    notifyListeners();
  }
  
  Future<void> saveMonthlyConversationCount(int count) async {
    _monthlyConversationCount = count;
    await _prefs.setInt(_monthlyConversationCountKey, count);
    notifyListeners();
  }
  
  Future<void> saveLastConversationDate(DateTime date) async {
    _lastConversationDate = date;
    await _prefs.setString(_lastConversationDateKey, date.toIso8601String());
    notifyListeners();
  }
  
  Future<void> saveLastMonthlyResetDate(DateTime date) async {
    _lastMonthlyResetDate = date;
    await _prefs.setString(_lastMonthlyResetDateKey, date.toIso8601String());
    notifyListeners();
  }
}
