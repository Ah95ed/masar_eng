import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import '../core/secure_storage.dart';
import '../widgets/in_app_notification_toast.dart';
import '../services/engineer_api.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/reports/report_detail_screen.dart';

/// نقطة الدخول لمهام الخلفية المستقلة (WorkManager - Android)
@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await SecureStorage.instance.init();
      final token = await SecureStorage.instance.readToken();
      if (token == null || token.isEmpty) return true;

      final uri = Uri.parse(
          'https://vehiclegate.ghusun.net/api/engineer.php?action=notifications');
      final client = http.Client();
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List rawList = [];
        if (body is List) {
          rawList = body;
        } else if (body is Map) {
          rawList = body['notifications'] ?? body['data'] ?? [];
        }

        final prefs = await SharedPreferences.getInstance();
        final lastSeenId = prefs.getInt('ml_last_seen_notif_id') ?? 0;

        int maxId = lastSeenId;
        for (final item in rawList) {
          if (item is Map) {
            final id = item['id'] is int
                ? item['id']
                : int.tryParse(item['id'].toString()) ?? 0;
            final isRead = (item['is_read'] == 1 ||
                item['is_read'] == true ||
                item['is_read'] == '1');

            if (id > lastSeenId && !isRead) {
              final title = item['title']?.toString() ?? 'إشعار جديد';
              final message = item['message']?.toString() ?? '';
              final link = item['link']?.toString() ?? '';

              final notifPlugin = FlutterLocalNotificationsPlugin();
              await notifPlugin.show(
                id: id,
                title: title,
                body: message,
                notificationDetails: NotificationDetails(
                  android: AndroidNotificationDetails(
                    'masar_engineer_channel',
                    'إشعارات مهندس مسار',
                    channelDescription:
                        'تنبيهات المهام والتقارير الميدانية والتحديثات',
                    importance: Importance.max,
                    priority: Priority.high,
                    playSound: true,
                    enableVibration: true,
                    styleInformation: BigTextStyleInformation(message),
                  ),
                ),
                payload: link,
              );

              if (id > maxId) maxId = id;
            }
          }
        }

        if (maxId > lastSeenId) {
          await prefs.setInt('ml_last_seen_notif_id', maxId);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Background notification error: $e');
      }
      return true;
    }
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  EngineerApi? _api;

  /// رد نداء التنقل عند النقر على إشعار النظام
  static void Function(String? payload)? onNotificationTapped;

  void setApi(EngineerApi api) {
    _api = api;
  }

  Future<void> init([EngineerApi? api]) async {
    if (api != null) _api = api;
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'open');

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _localNotifs.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (onNotificationTapped != null) {
            onNotificationTapped!(payload);
          } else {
            handleNotificationPayload(payload);
          }
        },
      );

      // تهيئة قناة الإشعارات وطلب الأذونات على أندرويد
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifs
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              'masar_engineer_channel',
              'إشعارات مهندس مسار',
              description: 'تنبيهات المهام والتقارير الميدانية والتحديثات',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // تهيئة مهام الخلفية WorkManager على نظام أندرويد
      if (!kIsWeb && Platform.isAndroid) {
        await Workmanager().initialize(
          notificationCallbackDispatcher,
        );

        await Workmanager().registerPeriodicTask(
          'masar_eng_background_notifs',
          'checkNotificationsTask',
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService init error: $e');
      }
    }

    _initialized = true;
  }

  /// إظهار إشعار نظام حقيقي (شريط الإشعارات للأندرويد وتوست الويندوز)
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifs.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'masar_engineer_channel',
            'إشعارات مهندس مسار',
            channelDescription:
                'تنبيهات المهام والتقارير الميدانية والتحديثات',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing system notification: $e');
      }
    }
  }

  /// إظهار توست / إشعار تفاعلي أنيق داخل التطبيق (سواء على الويندوز أو الهاتف)
  void showInAppNotification(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      notification,
      onTap: onTap,
    );
  }

  /// معالجة التوجيه الذكي عند النقر على الإشعار
  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || _api == null) return;

    final uri = Uri.tryParse('https://vehiclegate.ghusun.net/$payload');
    final query = uri?.queryParameters ?? {};
    final id = int.tryParse(query['id'] ?? '');

    if (payload.contains('tasks') || payload.contains('work_plans')) {
      if (id != null) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              api: _api!,
              task: {
                'id': id,
                'title': 'مهمة #$id',
                'site_name': '',
                'description': '',
                'priority': 'medium',
                'status': 'in_progress',
                'progress': 0,
              },
            ),
          ),
        );
      }
    } else if (payload.contains('reports')) {
      if (id != null) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(api: _api!, reportId: id),
          ),
        );
      }
    }
  }

  /// تحديث آخر معرف إشعار تم استعراضه لمنع التكرار
  Future<void> updateLastSeenId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('ml_last_seen_notif_id') ?? 0;
    if (id > current) {
      await prefs.setInt('ml_last_seen_notif_id', id);
    }
  }
}
