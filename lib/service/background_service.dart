/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../view/widgets/app_logger.dart';

class BackgroundNotificationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static const String notificationChannelId = 'notification_channel_id';
  static const String notificationChannelName = 'Notifications';
  static const _storage = FlutterSecureStorage();

  static Future<void> initializeService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Thai Massage Notifications',
        initialNotificationContent: 'Running in background...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    await _service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    final apiService = ApiService();
    WebSocketChannel? channel;
    int? roomId;

    // Fetch notification room ID
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        AppLogger.error('No access token found for background service');
        return;
      }

      final response = await apiService.client.get(
        Uri.parse('${ApiService.baseUrl}/api/notification/get-or-create-room/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        roomId = data['room_id'] as int?;
        AppLogger.debug('Background service fetched notification room ID: $roomId');
      } else {
        AppLogger.error('Failed to fetch notification room: ${response.body}');
        return;
      }
    } catch (e) {
      AppLogger.error('Error fetching notification room in background: $e');
      return;
    }

    if (roomId == null) return;

    // Connect to WebSocket
    try {
      channel = IOWebSocketChannel.connect(
        'ws://10.10.13.75:3333/ws/notifications/$roomId/',
      );
      AppLogger.debug('Background WebSocket connected for notifications');

      channel.stream.listen(
            (message) async {
          final data = jsonDecode(message) as Map<String, dynamic>;
          AppLogger.debug('Background WebSocket received: $data');
          await _showLocalNotification(data);
        },
        onError: (error) {
          AppLogger.error('Background WebSocket error: $error');
          _reconnect(service, roomId!);
        },
        onDone: () {
          AppLogger.debug('Background WebSocket connection closed');
          _reconnect(service, roomId!);
        },
      );
    } catch (e) {
      AppLogger.error('Background WebSocket connection error: $e');
      _reconnect(service, roomId!);
    }

    // Handle service stop
    service.on('stopService').listen((event) {
      channel?.sink.close();
      service.stopSelf();
    });
  }

  static Future<void> _reconnect(ServiceInstance service, int roomId) async {
    AppLogger.debug('Attempting to reconnect WebSocket in background...');
    await Future.delayed(const Duration(seconds: 5));
    if (!service.isStopped) {
      onStart(service);
    }
  }

  static Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: 'App notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.show(
      notification['id'] ?? 0,
      'New Notification',
      notification['message'] ?? 'You have a new notification',
      platformDetails,
      payload: jsonEncode(notification),
    );
  }
}*/
