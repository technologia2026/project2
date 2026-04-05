import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/medication.dart';
import '../screens/alarm_screen.dart';

// 💡 백그라운드 핸들러 (클래스 외부)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  print('백그라운드 알림 수신: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleMedicationNotifications(Medication med) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('isPushEnabled') ?? true)) return;

    for (int day in med.selectedDays) {
      for (int i = 0; i < med.doseTimes.length; i++) {
        final timeStr = med.doseTimes[i];
        final hour = int.parse(timeStr.split(':')[0]);
        final minute = int.parse(timeStr.split(':')[1]);

        final notificationId = (med.id + day.toString() + i.toString()).hashCode.abs() % 100000;
        String payload = jsonEncode({'medId': med.id, 'doseTime': timeStr});

        // 💡 모든 인자에 '이름:'을 붙였습니다.
        await _notifications.zonedSchedule(
          id: notificationId, // 👈 필수
          title: '💊 약 드실 시간이에요!',
          body: '${med.name} (${med.dosage}) 잊지 말고 챙겨 드세요!',
          scheduledDate: _nextOccurrence(day, hour, minute), // 👈 필수
          payload: payload,
          notificationDetails: NotificationDetails( // 👈 필수
            android: AndroidNotificationDetails(
              'medication_channel', 
              '약 복용 알림',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              enableVibration: prefs.getBool('isVibrationEnabled') ?? true,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 👈 필수
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  tz.TZDateTime _nextOccurrence(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    int daysUntil = day - now.weekday;
    if (daysUntil < 0 || (daysUntil == 0 && (now.hour > hour || (now.hour == hour && now.minute >= minute)))) {
      daysUntil += 7; 
    }
    return tz.TZDateTime(tz.local, now.year, now.month, now.day + daysUntil, hour, minute);
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (response.payload != null) {
      Map<String, dynamic> data = jsonDecode(response.payload!);
      final prefs = await SharedPreferences.getInstance();
      final String? medsJson = prefs.getString('medications');
      
      if (medsJson != null) {
        List<dynamic> decoded = jsonDecode(medsJson);
        List<Medication> allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
        
        try {
          Medication med = allMeds.firstWhere((m) => m.id == data['medId']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => AlarmScreen(medication: med, doseTime: data['doseTime']))
          );
        } catch (e) {
          print("알림 처리 에러: $e");
        }
      }
    }
  }

  Future<void> cancelNotifications(Medication med) async {
    for (int day in med.selectedDays) {
      for (int i = 0; i < med.doseTimes.length; i++) {
        final notificationId = (med.id + day.toString() + i.toString()).hashCode.abs() % 100000;
        // 💡 [수정] cancel 함수도 이름을 붙여서 호출합니다.
        await _notifications.cancel(id: notificationId); 
      }
    }
  }
}