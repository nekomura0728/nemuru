/// Web platform stub for flutter_local_notifications functionality
/// This provides mock implementations for web platform compatibility

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(
    InitializationSettings initializationSettings, {
    Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    // No-op for web
  }
  
  T? resolvePlatformSpecificImplementation<T>() {
    return null;
  }
  
  Future<void> cancel(int id) async {
    // No-op for web
  }
  
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    dynamic scheduledDate,
    NotificationDetails notificationDetails, {
    required dynamic uiLocalNotificationDateInterpretation,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidScheduleMode? androidScheduleMode,
  }) async {
    // No-op for web
  }
  
  Future<void> cancelAll() async {
    // No-op for web
  }
}

class InitializationSettings {
  final AndroidInitializationSettings? android;
  final DarwinInitializationSettings? iOS;
  
  const InitializationSettings({
    this.android,
    this.iOS,
  });
}

class AndroidInitializationSettings {
  final String defaultIcon;
  
  const AndroidInitializationSettings(this.defaultIcon);
}

class DarwinInitializationSettings {
  final bool requestAlertPermission;
  final bool requestBadgePermission;
  final bool requestSoundPermission;
  
  const DarwinInitializationSettings({
    required this.requestAlertPermission,
    required this.requestBadgePermission,
    required this.requestSoundPermission,
  });
}

class NotificationResponse {
  final int? id;
  final String? actionId;
  final String? input;
  final String? payload;
  
  NotificationResponse({
    this.id,
    this.actionId,
    this.input,
    this.payload,
  });
}

class NotificationDetails {
  final AndroidNotificationDetails? android;
  final DarwinNotificationDetails? iOS;
  
  const NotificationDetails({
    this.android,
    this.iOS,
  });
}

class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String? channelDescription;
  final String? icon;
  final Importance? importance;
  final Priority? priority;
  final bool? showWhen;
  
  const AndroidNotificationDetails(
    this.channelId,
    this.channelName, {
    this.channelDescription,
    this.icon,
    this.importance,
    this.priority,
    this.showWhen,
  });
}

class DarwinNotificationDetails {
  final bool? presentAlert;
  final bool? presentBadge;
  final bool? presentSound;
  
  const DarwinNotificationDetails({
    this.presentAlert,
    this.presentBadge,
    this.presentSound,
  });
}

class IOSFlutterLocalNotificationsPlugin {
  Future<bool?> requestPermissions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    return false;
  }
}

enum DateTimeComponents {
  time,
  dayOfWeekAndTime,
  dateAndTime,
}

enum Importance {
  unspecified,
  min,
  low,
  defaultImportance,
  high,
  max,
}

enum Priority {
  min,
  low,
  defaultPriority,
  high,
  max,
}

enum AndroidScheduleMode {
  exact,
  exactAllowWhileIdle,
  inexact,
  inexactAllowWhileIdle,
}

enum UILocalNotificationDateInterpretation {
  absoluteTime,
  wallClockTime,
}

// Timezone-related stubs
void initializeTimeZones() {
  // No-op for web
}