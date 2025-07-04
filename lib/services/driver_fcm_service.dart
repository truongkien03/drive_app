import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'navigation_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background FCM: ${message.data}');
  await DriverFCMService.handleBackgroundMessage(message);
}

class DriverFCMService {
  static FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM for Driver App
  static Future<void> initialize() async {
    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _initializeLocalNotifications();
      await _handleToken();
      _setupMessageHandlers();

      print('✅ Driver FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Driver FCM: $e');
    }
  }

  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Driver FCM permission granted');
    } else {
      print('❌ Driver FCM permission denied');
    }
  }

  static Future<void> _handleToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 Driver FCM Token: $token');
        await _sendTokenToServer(token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 Driver FCM Token refreshed: $newToken');
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      print('❌ Error handling FCM token: $e');
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final driverToken = await _getDriverToken();
      if (driverToken == null) {
        print('⚠️ No driver auth token, skipping FCM token upload');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverFCMToken}'),
        headers: {
          'Authorization': 'Bearer $driverToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Driver FCM token sent to server');
      } else {
        print('❌ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
    }
  }

  static Future<String?> _getDriverToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground FCM received: ${message.data}');
      _handleDriverNotificationData(message.data, isBackground: false);
      _showDriverNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Driver app opened from notification: ${message.data}');
      _handleNotificationClick(message.data);
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 Driver app launched from notification: ${message.data}');
        _handleNotificationClick(message.data);
      }
    });
  }

  static void _handleDriverNotificationData(Map<String, dynamic> data,
      {bool isBackground = true}) {
    String? key = data['key'];
    String? orderId = data['orderId'] ?? data['oderId'];

    switch (key) {
      case 'NewOrder':
      case 'NewOder':
        _handleNewOrderNotification(orderId, isBackground: isBackground);
        break;
      case 'OrderCancelled':
        _handleOrderCancelledNotification(orderId);
        break;
      case 'OrderShared':
        _handleOrderSharedNotification(orderId);
        break;
      default:
        print('⚠️ Unknown notification key: $key');
    }
  }

  static void _handleNewOrderNotification(String? orderId,
      {bool isBackground = true}) {
    if (orderId == null) return;
    print('🆕 New order notification: $orderId');

    if (!isBackground) {
      _showNewOrderDialog(orderId);
    }
  }

  static void _showNewOrderDialog(String orderId) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text('Đơn hàng mới!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn có đơn hàng mới cần xác nhận!',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Thời gian phản hồi: 60 giây',
                  style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate using route name instead of direct class import
                NavigationService.navigateToRoute('/order-acceptance',
                    arguments: {'orderId': orderId});
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Xem ngay'),
            ),
          ],
        );
      },
    );
  }

  static void _handleOrderCancelledNotification(String? orderId) {
    if (orderId == null) return;
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.cancel, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
                child: Text('Đơn hàng #$orderId đã bị hủy bởi khách hàng')),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _handleOrderSharedNotification(String? orderId) {
    if (orderId == null) return;
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Bạn được mời nhận đơn hàng #$orderId')),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    String? link = data['link'];
    String? orderId = data['orderId'] ?? data['oderId'];

    if (link != null && orderId != null) {
      switch (link) {
        case 'driver://AwaitAcceptOder':
        case 'driver://AwaitAcceptOrder':
          NavigationService.navigateToRoute('/order-acceptance',
              arguments: {'orderId': orderId});
          break;
        case 'driver://OrderShared':
          NavigationService.navigateToRoute('/shared-order',
              arguments: {'orderId': orderId});
          break;
        default:
          print('⚠️ Unknown deep link: $link');
      }
    }
  }

  static void _showDriverNotification(RemoteMessage message) {
    final title = message.notification?.title ?? '🚚 Thông báo tài xế';
    final body = message.notification?.body ?? 'Bạn có thông báo mới';

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'driver_orders',
          'Driver Orders',
          channelDescription: 'Notifications for driver orders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationClick(data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('🔔 Handling background message: ${message.data}');
    _handleDriverNotificationData(message.data, isBackground: true);
  }

  static Future<void> removeToken() async {
    try {
      final driverToken = await _getDriverToken();
      if (driverToken != null) {
        await http.delete(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.driverFCMToken}'),
          headers: {
            'Authorization': 'Bearer $driverToken',
            'Content-Type': 'application/json',
          },
        );
      }

      await _messaging.deleteToken();
      print('✅ Driver FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> sendCurrentTokenToServer() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 Sending current FCM token to server: $token');
        await _sendTokenToServer(token);
      } else {
        print('⚠️ No FCM token available to send');
      }
    } catch (e) {
      print('❌ Error sending current FCM token: $e');
    }
  }
}
