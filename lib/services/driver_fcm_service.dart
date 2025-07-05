import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/order.dart';
import '../widgets/new_order_dialog.dart';
import '../services/navigation_service.dart';
import 'notification_service.dart';

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
  static final NotificationService _notificationService = NotificationService();

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

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationClick(details.payload);
      },
    );

    print('✅ Local notifications initialized');
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
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error getting driver token: $e');
      return null;
    }
  }

  // Setup message handlers
  static void _setupMessageHandlers() {
    // Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground FCM: ${message.data}');
      _handleForegroundMessage(message);
    });

    // Background/terminated message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Message opened app: ${message.data}');
      _handleMessageOpenedApp(message);
    });

    // Check for initial message (app launched from notification)
    _checkInitialMessage();
  }

  // Handle foreground message (app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final actionType = data['action_type']?.toString() ?? '';

      print('📱 Processing foreground notification: $actionType');

      // Create notification object
      final notification = _notificationService.createFromFCMData(
        data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

      // Save to local storage
      await _notificationService.addLocalNotification(notification);

      // For new orders, show dialog immediately (don't show local notification)
      if (actionType == 'new_order' || actionType == 'order_shared') {
        // Show dialog directly for immediate action
        await _handleNotificationAction(actionType, data);
      } else {
        // For other notifications, show local notification
        await _showLocalNotification(message);

        // Handle other actions
        await _handleNotificationAction(actionType, data);
      }
    } catch (e) {
      print('❌ Error handling foreground message: $e');
    }
  }

  // Handle background message (must be static top-level function)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final actionType = data['action_type']?.toString() ?? '';

      print('🔔 Processing background notification: $actionType');

      // Create notification object
      final notificationService = NotificationService();
      final notification = notificationService.createFromFCMData(
        data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

      // Save to local storage
      await notificationService.addLocalNotification(notification);
    } catch (e) {
      print('❌ Error handling background message: $e');
    }
  }

  // Handle message when app is opened from notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      final data = message.data;
      final actionType = data['action_type']?.toString() ?? '';

      print('📱 App opened from notification: $actionType');

      // Handle navigation based on action type
      await _handleNotificationAction(actionType, data);
    } catch (e) {
      print('❌ Error handling message opened app: $e');
    }
  }

  // Check for initial message when app starts
  static Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        print('🔔 App launched from notification: ${initialMessage.data}');
        await _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      print('❌ Error checking initial message: $e');
    }
  }

  // Handle notification actions based on type
  static Future<void> _handleNotificationAction(
      String actionType, Map<String, dynamic> data) async {
    final orderId = data['order_id']?.toString() ?? '';

    switch (actionType) {
      case 'new_order':
        print('🚚 New order notification: $orderId');
        await _handleNewOrderNotification(data);
        break;

      case 'order_cancelled':
        print('❌ Order cancelled: $orderId');
        _showOrderCancelledMessage(orderId);
        break;

      case 'order_shared':
        print('🤝 Order shared: $orderId');
        final sharedBy = data['shared_by']?.toString() ?? '';
        print('   Shared by driver: $sharedBy');
        await _handleSharedOrderNotification(data);
        break;

      default:
        print('🔔 System notification');
        break;
    }
  }

  // Handle new order notification - show dialog
  static Future<void> _handleNewOrderNotification(
      Map<String, dynamic> data) async {
    try {
      // Parse order data from FCM
      final order = Order.fromFCMData(data);

      // Get current context
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        print('❌ No context available for showing order dialog');
        return;
      }

      // Show new order dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible:
            false, // Không cho phép đóng dialog bằng cách tap outside
        builder: (context) => NewOrderDialog(
          order: order,
          onAccepted: () {
            print('✅ Order ${order.id} accepted by driver');
          },
          onDeclined: () {
            print('❌ Order ${order.id} declined by driver');
          },
        ),
      );

      if (result == true) {
        print('🎉 Driver accepted order ${order.id}');
        // TODO: Navigate to order tracking screen or update UI
      } else {
        print('💔 Driver declined order ${order.id}');
      }
    } catch (e) {
      print('❌ Error handling new order notification: $e');
    }
  }

  // Handle shared order notification
  static Future<void> _handleSharedOrderNotification(
      Map<String, dynamic> data) async {
    try {
      // Parse order data from FCM (shared orders có thể có format khác)
      final order = Order.fromFCMData(data);
      final sharedBy = data['shared_by']?.toString() ?? '';

      // Get current context
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        print('❌ No context available for showing shared order dialog');
        return;
      }

      // Show shared order dialog với thông tin bổ sung
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => NewOrderDialog(
          order: order,
          onAccepted: () {
            print('✅ Shared order ${order.id} accepted by driver');
          },
          onDeclined: () {
            print('❌ Shared order ${order.id} declined by driver');
          },
        ),
      );

      if (result == true) {
        print(
            '🎉 Driver accepted shared order ${order.id} from driver $sharedBy');
      } else {
        print('💔 Driver declined shared order ${order.id}');
      }
    } catch (e) {
      print('❌ Error handling shared order notification: $e');
    }
  }

  // Show order cancelled message
  static void _showOrderCancelledMessage(String orderId) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Đơn hàng #$orderId đã bị khách hàng hủy'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'driver_channel',
        'Driver Notifications',
        channelDescription: 'Notifications for driver app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title =
          message.notification?.title ?? _getDefaultTitle(message.data);
      final body = message.notification?.body ?? _getDefaultBody(message.data);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Get default title based on action type
  static String _getDefaultTitle(Map<String, dynamic> data) {
    final actionType = data['action_type']?.toString() ?? '';

    switch (actionType) {
      case 'new_order':
        return '🚚 Đơn hàng mới';
      case 'order_cancelled':
        return '❌ Đơn hàng bị hủy';
      case 'order_shared':
        return '🤝 Đơn hàng chia sẻ';
      default:
        return '🔔 Thông báo mới';
    }
  }

  // Get default body based on action type
  static String _getDefaultBody(Map<String, dynamic> data) {
    final actionType = data['action_type']?.toString() ?? '';
    final orderId = data['order_id']?.toString() ?? '';

    switch (actionType) {
      case 'new_order':
        final distance = data['distance']?.toString() ?? '';
        return 'Có đơn hàng mới #$orderId${distance.isNotEmpty ? ' (cách $distance km)' : ''}';
      case 'order_cancelled':
        return 'Đơn hàng #$orderId đã bị hủy bởi khách hàng';
      case 'order_shared':
        final sharedBy = data['shared_by']?.toString() ?? '';
        return 'Bạn được mời nhận đơn hàng #$orderId${sharedBy.isNotEmpty ? ' từ tài xế #$sharedBy' : ''}';
      default:
        return 'Bạn có thông báo mới';
    }
  }

  // Handle notification click
  static void _handleNotificationClick(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final actionType = data['action_type']?.toString() ?? '';
        print('🔔 Notification clicked: $actionType');

        // Handle navigation
        _handleNotificationAction(actionType, data);
      } catch (e) {
        print('❌ Error handling notification click: $e');
      }
    }
  }

  // Remove FCM token when logout
  static Future<void> removeToken() async {
    try {
      final driverToken = await _getDriverToken();
      if (driverToken == null) {
        print('⚠️ No driver auth token for removing FCM token');
        return;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverFCMToken}'),
        headers: {
          'Authorization': 'Bearer $driverToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Driver FCM token removed from server');
      } else {
        print('❌ Failed to remove FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  // Subscribe to driver topic
  static Future<void> subscribeToDriverTopic(int driverId) async {
    try {
      await _messaging.subscribeToTopic('driver-$driverId');
      print('✅ Subscribed to topic: driver-$driverId');
    } catch (e) {
      print('❌ Error subscribing to driver topic: $e');
    }
  }

  // Unsubscribe from driver topic
  static Future<void> unsubscribeFromDriverTopic(int driverId) async {
    try {
      await _messaging.unsubscribeFromTopic('driver-$driverId');
      print('✅ Unsubscribed from topic: driver-$driverId');
    } catch (e) {
      print('❌ Error unsubscribing from driver topic: $e');
    }
  }

  // Subscribe to all driver topics for receiving orders
  static Future<void> subscribeToDriverTopics(int driverId) async {
    try {
      // Subscribe to general driver topic
      await _messaging.subscribeToTopic('all-drivers');
      print('✅ Subscribed to topic: all-drivers');

      // Subscribe to specific driver topic (if driverId is valid)
      if (driverId > 0) {
        await _messaging.subscribeToTopic('driver-$driverId');
        print('✅ Subscribed to topic: driver-$driverId');
      }
    } catch (e) {
      print('❌ Error subscribing to driver topics: $e');
    }
  }

  // Unsubscribe from all driver topics
  static Future<void> unsubscribeFromDriverTopics(int driverId) async {
    try {
      // Unsubscribe from general driver topic
      await _messaging.unsubscribeFromTopic('all-drivers');
      print('✅ Unsubscribed from topic: all-drivers');

      // Unsubscribe from specific driver topic (if driverId is valid)
      if (driverId > 0) {
        await _messaging.unsubscribeFromTopic('driver-$driverId');
        print('✅ Unsubscribed from topic: driver-$driverId');
      }
    } catch (e) {
      print('❌ Error unsubscribing from driver topics: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Send current token to server manually
  static Future<void> sendCurrentTokenToServer() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      print('❌ Error sending current token to server: $e');
    }
  }
}
