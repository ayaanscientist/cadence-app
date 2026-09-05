import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// High-priority alarm classifications for AtomicOS.
enum AlarmType {
  meditation(101, 'Meditation Routine', 'meditation_channel', 'Meditation Alerts'),
  windDown(102, 'Sleep Wind-Down', 'wind_down_channel', 'Wind-Down Alerts'),
  wakeUp(103, 'Wake-Up Call', 'wake_up_channel', 'Wake-Up Alarms');

  const AlarmType(this.id, this.defaultTitle, this.channelId, this.channelName);

  final int id;
  final String defaultTitle;
  final String channelId;
  final String channelName;
}

/// Persistent configuration model for an exact alarm.
class AlarmConfig {

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      type: AlarmType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlarmType.meditation,
      ),
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
  const AlarmConfig({
    required this.type,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.isEnabled = true,
  });

  final AlarmType type;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final bool isEnabled;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'hour': hour,
        'minute': minute,
        'title': title,
        'body': body,
        'isEnabled': isEnabled,
      };
}

/// Top-level static callback for AndroidAlarmManager.
///
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter's
/// background engine does not tree-shake it.
@pragma('vm:entry-point')
void alarmManagerCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final notifications = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(const InitializationSettings(android: androidInit));

  AlarmType type = AlarmType.values.firstWhere(
    (e) => e.id == id,
    orElse: () => AlarmType.meditation,
  );

  final androidDetails = AndroidNotificationDetails(
    type.channelId,
    type.channelName,
    channelDescription: 'Exact scheduled alarm trigger for AtomicOS',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    enableVibration: true,
    playSound: true,
  );

  await notifications.show(
    id,
    type.defaultTitle,
    'Scheduled cadence alarm is ringing. Tap to begin routine.',
    NotificationDetails(android: androidDetails),
  );
}

/// Offline-first exact Alarm and Notification Service.
///
/// Orchestrates native Android `AlarmManager` (with `setExactAndAllowWhileIdle`)
/// and `flutter_local_notifications` with offline persistence for automatic
/// rescheduling across device reboots (`BOOT_COMPLETED`).
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const String _prefsKeyPrefix = 'atomic_os_alarm_config_';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes notification channels, AndroidAlarmManager, and timezones.
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createNotificationChannels();
    _isInitialized = true;
  }

  /// Create dedicated Android notification channels for each alarm type.
  Future<void> _createNotificationChannels() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      for (final type in AlarmType.values) {
        await androidImpl.createNotificationChannel(
          AndroidNotificationChannel(
            type.channelId,
            type.channelName,
            description: 'AtomicOS Exact Channel for ${type.channelName}',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }
  }

  /// Schedules an exact daily recurring alarm for the given [AlarmType].
  Future<void> scheduleDailyAlarm({
    required AlarmType type,
    required TimeOfDay time,
    String? title,
    String? body,
  }) async {
    await initialize();

    final alarmTitle = title ?? type.defaultTitle;
    final alarmBody = body ?? 'Scheduled cadence alarm for ${type.channelName}.';

    // 1. Persist alarm schedule locally for reboot resilience
    final config = AlarmConfig(
      type: type,
      hour: time.hour,
      minute: time.minute,
      title: alarmTitle,
      body: alarmBody,
      isEnabled: true,
    );
    await _persistAlarmConfig(config);

    // 2. Calculate next target DateTime
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    // 3. Register with AndroidAlarmManager for exact wake-up execution
    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        scheduledDateTime,
        type.id,
        alarmManagerCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }

    // 4. Also register with flutter_local_notifications with exact TZ schedule
    final tzLocation = tz.local;
    final tzScheduledDate = tz.TZDateTime.from(scheduledDateTime, tzLocation);

    final androidDetails = AndroidNotificationDetails(
      type.channelId,
      type.channelName,
      channelDescription: 'Exact scheduled notification for ${type.channelName}',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin.zonedSchedule(
      type.id,
      alarmTitle,
      alarmBody,
      tzScheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels an existing alarm by its type.
  Future<void> cancelAlarm(AlarmType type) async {
    await initialize();

    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(type.id);
    }
    await _notificationsPlugin.cancel(type.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix${type.name}');
  }

  /// Cancels all scheduled alarms and clears stored configurations.
  Future<void> cancelAllAlarms() async {
    await initialize();

    for (final type in AlarmType.values) {
      if (Platform.isAndroid) {
        await AndroidAlarmManager.cancel(type.id);
      }
      await _notificationsPlugin.cancel(type.id);
    }

    final prefs = await SharedPreferences.getInstance();
    for (final type in AlarmType.values) {
      await prefs.remove('$_prefsKeyPrefix${type.name}');
    }
  }

  /// Retrieves all configured alarms from offline persistent storage.
  Future<List<AlarmConfig>> getScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final configs = <AlarmConfig>[];

    for (final type in AlarmType.values) {
      final raw = prefs.getString('$_prefsKeyPrefix${type.name}');
      if (raw != null) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          configs.add(AlarmConfig.fromJson(json));
        } catch (_) {}
      }
    }
    return configs;
  }

  /// Re-arms all saved alarms after device restart (BOOT_COMPLETED).
  ///
  /// This method is called upon application launch or boot receiver.
  Future<void> rescheduleOnBoot() async {
    await initialize();
    final savedConfigs = await getScheduledAlarms();

    for (final config in savedConfigs) {
      if (config.isEnabled) {
        await scheduleDailyAlarm(
          type: config.type,
          time: TimeOfDay(hour: config.hour, minute: config.minute),
          title: config.title,
          body: config.body,
        );
      }
    }
  }

  Future<void> _persistAlarmConfig(AlarmConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyPrefix${config.type.name}',
      jsonEncode(config.toJson()),
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle foreground action or navigation upon tapping notification.
  }
}
