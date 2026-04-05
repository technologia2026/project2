// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones(); 
    tz.setLocalLocation(tz.getLocation('Asia/Seoul')); 
    
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher'); 
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit, 
      iOS: iosInit, 
    );

    await _notifications.initialize(
      settings: initSettings, 
    );
  }

  // 🔔 권한 요청 팝업 띄우기
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true, badge: true, sound: true,
      );
    } else if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // 💊 특정 약의 알림 모두 등록
  Future<void> scheduleMedicationNotifications(Medication med) async {
    final prefs = await SharedPreferences.getInstance();
    bool isPushEnabled = prefs.getBool('isPushEnabled') ?? true; 
    bool isVibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true; 

    if (!isPushEnabled) {
      print("🔔 알림 설정이 꺼져 있어 ${med.name} 알림을 예약하지 않습니다.");
      return; 
    }

    for (int day in med.selectedDays) {
      for (int i = 0; i < med.doseTimes.length; i++) {
        final timeStr = med.doseTimes[i];
        final hour = int.parse(timeStr.split(':')[0]);
        final minute = int.parse(timeStr.split(':')[1]);

        final notificationId = (med.id + day.toString() + i.toString()).hashCode.abs() % 100000;

        await _notifications.zonedSchedule(
          id: notificationId,
          title: '💊 약 드실 시간이에요!',
          body: '${med.name} (${med.dosage}) 잊지 말고 챙겨 드세요!',
          scheduledDate: _nextOccurrence(day, hour, minute),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_channel', '약 복용 알림',
              channelDescription: '약 먹을 시간을 알려줍니다.',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: isVibrationEnabled, 
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, 
        );
      }
    }
  }

  // 다음 알람이 울릴 정확한 날짜/시간 계산
  tz.TZDateTime _nextOccurrence(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    int daysUntil = day - now.weekday;
    
    if (daysUntil < 0 || (daysUntil == 0 && (now.hour > hour || (now.hour == hour && now.minute >= minute)))) {
      daysUntil += 7; 
    }
    return tz.TZDateTime(tz.local, now.year, now.month, now.day + daysUntil, hour, minute);
  }
}