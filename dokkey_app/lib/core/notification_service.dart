import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Morning Notification Scheduler (v3.0.0 P4)
/// Android 네이티브에서만 동작하며, Web/데스크톱에서는 자동 no-op 처리된다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const int _dailyId = 1001;
  static const String _channelId = 'dokkey_morning';
  static const String _channelName = 'DOK-KEY Morning Key';

  Future<void> initialize() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// 매일 지정 시각에 "오늘의 열쇠" 알림 예약
  Future<void> scheduleDaily({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await initialize();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _dailyId);
      if (!enabled) return;

      // Android 13+ (API 33+) 알림 런타임 권한 명시적 요청
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'DOK-KEY daily key notification',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _dailyId,
        title: 'DOK-KEY 🔑',
        body: '오늘 하루를 여는 단 하나의 열쇠가 도착했습니다!',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
    }
  }
}
