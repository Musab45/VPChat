import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Service for managing app settings
class SettingsService {
  static const String _settingsKey = 'app_settings';
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  AppSettings? _cachedSettings;

  /// Get current settings
  Future<AppSettings> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson == null || settingsJson.isEmpty) {
      _cachedSettings = AppSettings();
      return _cachedSettings!;
    }

    try {
      final decoded = jsonDecode(settingsJson);
      _cachedSettings = AppSettings.fromJson(decoded);
      return _cachedSettings!;
    } catch (e) {
      _cachedSettings = AppSettings();
      return _cachedSettings!;
    }
  }

  /// Save settings
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    _cachedSettings = settings;
  }

  /// Update a single setting
  Future<void> updateSetting<T>(String key, T value) async {
    final settings = await getSettings();
    final updated = settings.copyWithKey(key, value);
    await saveSettings(updated);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    _cachedSettings = AppSettings();
  }

  /// Clear cache
  void clearCache() {
    _cachedSettings = null;
  }
}

/// App settings model
class AppSettings {
  // Appearance
  final AppThemeMode themeMode;
  final double fontSize;
  final bool compactMode;

  // Chat
  final bool enterToSend;
  final bool showTypingIndicator;
  final bool autoDownloadMedia;
  final MediaDownloadOption mediaDownloadOnWifi;
  final MediaDownloadOption mediaDownloadOnMobile;

  // Notifications
  final NotificationSettings notifications;

  // Privacy
  final bool showOnlineStatus;
  final bool showReadReceipts;
  final bool showTypingStatus;
  final LastSeenVisibility lastSeenVisibility;

  // Storage
  final bool autoDeleteOldMessages;
  final int autoDeleteDays;

  AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.fontSize = 1.0,
    this.compactMode = false,
    this.enterToSend = true,
    this.showTypingIndicator = true,
    this.autoDownloadMedia = true,
    this.mediaDownloadOnWifi = MediaDownloadOption.all,
    this.mediaDownloadOnMobile = MediaDownloadOption.images,
    NotificationSettings? notifications,
    this.showOnlineStatus = true,
    this.showReadReceipts = true,
    this.showTypingStatus = true,
    this.lastSeenVisibility = LastSeenVisibility.everyone,
    this.autoDeleteOldMessages = false,
    this.autoDeleteDays = 30,
  }) : notifications = notifications ?? NotificationSettings();

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? fontSize,
    bool? compactMode,
    bool? enterToSend,
    bool? showTypingIndicator,
    bool? autoDownloadMedia,
    MediaDownloadOption? mediaDownloadOnWifi,
    MediaDownloadOption? mediaDownloadOnMobile,
    NotificationSettings? notifications,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingStatus,
    LastSeenVisibility? lastSeenVisibility,
    bool? autoDeleteOldMessages,
    int? autoDeleteDays,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      compactMode: compactMode ?? this.compactMode,
      enterToSend: enterToSend ?? this.enterToSend,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      mediaDownloadOnWifi: mediaDownloadOnWifi ?? this.mediaDownloadOnWifi,
      mediaDownloadOnMobile:
          mediaDownloadOnMobile ?? this.mediaDownloadOnMobile,
      notifications: notifications ?? this.notifications,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingStatus: showTypingStatus ?? this.showTypingStatus,
      lastSeenVisibility: lastSeenVisibility ?? this.lastSeenVisibility,
      autoDeleteOldMessages:
          autoDeleteOldMessages ?? this.autoDeleteOldMessages,
      autoDeleteDays: autoDeleteDays ?? this.autoDeleteDays,
    );
  }

  AppSettings copyWithKey(String key, dynamic value) {
    switch (key) {
      case 'themeMode':
        return copyWith(themeMode: value as AppThemeMode);
      case 'fontSize':
        return copyWith(fontSize: value as double);
      case 'compactMode':
        return copyWith(compactMode: value as bool);
      case 'enterToSend':
        return copyWith(enterToSend: value as bool);
      case 'showTypingIndicator':
        return copyWith(showTypingIndicator: value as bool);
      case 'autoDownloadMedia':
        return copyWith(autoDownloadMedia: value as bool);
      case 'showOnlineStatus':
        return copyWith(showOnlineStatus: value as bool);
      case 'showReadReceipts':
        return copyWith(showReadReceipts: value as bool);
      case 'showTypingStatus':
        return copyWith(showTypingStatus: value as bool);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'fontSize': fontSize,
      'compactMode': compactMode,
      'enterToSend': enterToSend,
      'showTypingIndicator': showTypingIndicator,
      'autoDownloadMedia': autoDownloadMedia,
      'mediaDownloadOnWifi': mediaDownloadOnWifi.index,
      'mediaDownloadOnMobile': mediaDownloadOnMobile.index,
      'notifications': notifications.toJson(),
      'showOnlineStatus': showOnlineStatus,
      'showReadReceipts': showReadReceipts,
      'showTypingStatus': showTypingStatus,
      'lastSeenVisibility': lastSeenVisibility.index,
      'autoDeleteOldMessages': autoDeleteOldMessages,
      'autoDeleteDays': autoDeleteDays,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 1],
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
      compactMode: json['compactMode'] as bool? ?? false,
      enterToSend: json['enterToSend'] as bool? ?? true,
      showTypingIndicator: json['showTypingIndicator'] as bool? ?? true,
      autoDownloadMedia: json['autoDownloadMedia'] as bool? ?? true,
      mediaDownloadOnWifi:
          MediaDownloadOption.values[json['mediaDownloadOnWifi'] as int? ?? 0],
      mediaDownloadOnMobile: MediaDownloadOption
          .values[json['mediaDownloadOnMobile'] as int? ?? 1],
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(json['notifications'])
          : NotificationSettings(),
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      showReadReceipts: json['showReadReceipts'] as bool? ?? true,
      showTypingStatus: json['showTypingStatus'] as bool? ?? true,
      lastSeenVisibility:
          LastSeenVisibility.values[json['lastSeenVisibility'] as int? ?? 0],
      autoDeleteOldMessages: json['autoDeleteOldMessages'] as bool? ?? false,
      autoDeleteDays: json['autoDeleteDays'] as int? ?? 30,
    );
  }
}

enum AppThemeMode { light, dark, system }

enum MediaDownloadOption { all, images, none }

enum LastSeenVisibility { everyone, contacts, nobody }
