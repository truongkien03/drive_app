import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/order2.dart';
import '../widgets/new_order_dialog.dart';
import '../services/navigation_service.dart';
import '../services/api_service.dart';
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
      // Use the correct key that matches AuthService
      return prefs.getString('accessToken');
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

      // Support both old and new FCM formats
      final actionType = data['action_type']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';
      final key = data['key']?.toString() ?? '';

      print('📱 Processing foreground notification:');
      print('   - action_type: $actionType');
      print('   - type: $type');
      print('   - key: $key');
      print('   - data: $data');

      // Create notification object
      final notification = _notificationService.createFromFCMData(
        data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

      // Save to local storage
      await _notificationService.addLocalNotification(notification);

      // Handle new order notifications (new format - support both key "NewOder" and type "new_order_available")
      if (type == 'new_order_available' || key == 'NewOder') {
        print('🚚 New order notification detected (new format)');
        await _handleNewOrderNotification(data);
      }
      // Handle old format
      else if (actionType == 'new_order' || actionType == 'order_shared') {
        print('📦 Order notification detected (old format)');
        await _handleNotificationAction(actionType, data);
      } else {
        // For other notifications, show local notification
        await _showLocalNotification(message);
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
      final type = data['type']?.toString() ?? '';
      final key = data['key']?.toString() ?? '';

      print('🔔 Processing background notification:');
      print('   - action_type: $actionType');
      print('   - type: $type');
      print('   - key: $key');

      // Create notification object
      final notificationService = NotificationService();
      final notification = notificationService.createFromFCMData(
        data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

      // Save to local storage
      await notificationService.addLocalNotification(notification);

      // Show local notification for background orders
      if (type == 'new_order_available' || key == 'NewOder') {
        await _showLocalNotificationForOrder(data);
      }
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
    final orderId =
        data['order_id']?.toString() ?? data['oderId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final key = data['key']?.toString() ?? '';

    // Handle new format first
    if (type == 'new_order_available' || key == 'NewOder') {
      print('🚚 New order notification (new format): $orderId');
      await _handleNewOrderNotification(data);
      return;
    }

    // Handle old format
    switch (actionType) {
      case 'new_order':
        print('🚚 New order notification (old format): $orderId');
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
      print('🚚 Processing new order notification with data: $data');

      // Parse order data from FCM (new format)
      final orderId =
          data['oderId']?.toString() ?? data['order_id']?.toString() ?? '';
      final distance = data['distance']?.toString() ?? '';
      final shippingCost = data['shipping_cost']?.toString() ?? '';

      // Parse addresses (they come as JSON strings)
      Map<String, dynamic> fromAddress = {};
      Map<String, dynamic> toAddress = {};

      try {
        if (data['from_address'] != null) {
          fromAddress = jsonDecode(data['from_address']);
        }
        if (data['to_address'] != null) {
          toAddress = jsonDecode(data['to_address']);
        }
      } catch (e) {
        print('⚠️ Error parsing address data: $e');
      }

      print('📋 Order Details:');
      print('   - Order ID: $orderId');
      print('   - Distance: ${distance}km');
      print('   - Shipping Cost: ${shippingCost} VND');
      print('   - From: ${fromAddress['desc'] ?? 'Unknown'}');
      print('   - To: ${toAddress['desc'] ?? 'Unknown'}');

      // Get current context
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        print('❌ No context available for showing order dialog');
        // Fallback: show local notification
        await _showLocalNotificationForOrder(data);
        return;
      }

      // Try to create Order object if possible (fallback to old format)
      Order? order;
      try {
        order = Order.fromFCMData(data);
      } catch (e) {
        print(
            '⚠️ Could not create Order object from FCM data, using simple dialog: $e');
      }

      // Show dialog based on available data
      if (order != null) {
        // Use existing NewOrderDialog if Order object is available
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => NewOrderDialog(
            order: order!,
            onAccepted: () {
              print('✅ Order ${order!.id} accepted by driver');
            },
            onDeclined: () {
              print('❌ Order ${order!.id} declined by driver');
            },
          ),
        );

        if (result == true) {
          print('🎉 Driver accepted order ${order.id}');
        } else {
          print('💔 Driver declined order ${order.id}');
        }
      } else {
        // Use simple dialog for new FCM format
        await _showSimpleOrderDialog(
          context: context,
          orderId: orderId,
          fromAddress: fromAddress,
          toAddress: toAddress,
          distance: distance,
          shippingCost: shippingCost,
          rawData: data,
        );
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
    final type = data['type']?.toString() ?? '';
    final key = data['key']?.toString() ?? '';

    // Handle new format
    if (type == 'new_order_available' || key == 'NewOder') {
      return '🚚 Đơn hàng mới cần giao!';
    }

    // Handle old format
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
    final type = data['type']?.toString() ?? '';
    final key = data['key']?.toString() ?? '';
    final orderId =
        data['order_id']?.toString() ?? data['oderId']?.toString() ?? '';

    // Handle new format
    if (type == 'new_order_available' || key == 'NewOder') {
      final distance = data['distance']?.toString() ?? '';
      final shippingCost = data['shipping_cost']?.toString() ?? '';
      String bodyText = 'Có đơn hàng mới trong khu vực của bạn.';
      if (distance.isNotEmpty) {
        bodyText += ' Khoảng cách: ${distance}km';
      }
      if (shippingCost.isNotEmpty) {
        try {
          final cost = int.parse(shippingCost);
          final formattedCost = cost.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
          );
          bodyText += ' - Phí: ${formattedCost} VND';
        } catch (e) {
          bodyText += ' - Phí: $shippingCost VND';
        }
      }
      return bodyText;
    }

    // Handle old format
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

  // Refresh and send FCM token to server
  static Future<void> refreshFCMToken() async {
    try {
      print('🔄 Refreshing FCM token...');

      // Get current token
      final token = await getToken();
      if (token != null) {
        print('📱 Current FCM token: ${token.substring(0, 50)}...');

        // Send to server
        await _sendTokenToServer(token);
        print('✅ FCM token refreshed and sent to server');
      } else {
        print('❌ No FCM token available to refresh');
      }
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
    }
  }

  // ...existing code...
  // Show simple order dialog for new FCM format
  static Future<void> _showSimpleOrderDialog({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> fromAddress,
    required Map<String, dynamic> toAddress,
    required String distance,
    required String shippingCost,
    required Map<String, dynamic> rawData,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Đơn hàng mới #$orderId'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distance and cost
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.straighten, color: Colors.green),
                            SizedBox(height: 4),
                            Text('${distance}km',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green),
                            SizedBox(height: 4),
                            Text('${_formatCurrency(shippingCost)} VND',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // From address
                _buildAddressCard(
                  title: '📍 Điểm lấy hàng',
                  address: fromAddress['desc']?.toString() ?? 'Không xác định',
                  lat: fromAddress['lat']?.toString(),
                  lon: fromAddress['lon']?.toString(),
                ),
                SizedBox(height: 12),

                // To address
                _buildAddressCard(
                  title: '📍 Điểm giao hàng',
                  address: toAddress['desc']?.toString() ?? 'Không xác định',
                  lat: toAddress['lat']?.toString(),
                  lon: toAddress['lon']?.toString(),
                ),
                SizedBox(height: 16),

                // Timestamp
                if (rawData['timestamp'] != null)
                  Text(
                    'Thời gian: ${_formatTimestamp(rawData['timestamp'])}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                print('❌ Order #$orderId declined by user');
              },
              child: Text('Từ chối', style: TextStyle(color: Colors.red)),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
                _acceptOrder(orderId, rawData);
              },
              icon: Icon(Icons.check),
              label: Text('Nhận đơn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      print('🎉 Driver accepted order #$orderId');
    } else {
      print('💔 Driver declined order #$orderId');
    }
  }

  // Helper method to build address card
  static Widget _buildAddressCard({
    required String title,
    required String address,
    String? lat,
    String? lon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 4),
          Text(address, style: TextStyle(fontSize: 13)),
          if (lat != null && lon != null)
            Text(
              'Tọa độ: $lat, $lon',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
        ],
      ),
    );
  }

  // Accept order
  static Future<void> _acceptOrder(
      String orderId, Map<String, dynamic> orderData) async {
    try {
      print('✅ Accepting order #$orderId');

      final apiService = ApiService();
      final response = await apiService.acceptOrder(int.parse(orderId));

      if (response.success) {
        print('🎉 Order #$orderId accepted successfully');

        // Navigate to order tracking screen
        final context = NavigationService.navigatorKey.currentContext;
        if (context != null) {
          // TODO: Navigate to order tracking screen
          // Navigator.pushNamed(context, '/order-tracking', arguments: orderId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã nhận đơn hàng #$orderId thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Failed to accept order: ${response.message}');
        _showErrorSnackBar('Không thể nhận đơn: ${response.message}');
      }
    } catch (e) {
      print('❌ Error accepting order: $e');
      _showErrorSnackBar('Lỗi khi nhận đơn: $e');
    }
  }

  // Helper methods
  static String _formatCurrency(String amount) {
    try {
      final number = int.parse(amount);
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      );
    } catch (e) {
      return amount;
    }
  }

  static String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  static void _showErrorSnackBar(String message) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fallback local notification for orders
  static Future<void> _showLocalNotificationForOrder(
      Map<String, dynamic> data) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_orders',
      'Driver Orders',
      channelDescription: 'Notifications for new orders',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('driver_alert'),
    );

    const iosDetails = DarwinNotificationDetails(
      sound: null,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final orderId = data['oderId'] ?? data['order_id'] ?? 'Unknown';
    final distance = data['distance'] ?? '0';

    await _localNotifications.show(
      int.tryParse(orderId.toString()) ?? 0,
      'Đơn hàng mới #$orderId',
      'Khoảng cách: ${distance}km - Nhấn để xem chi tiết',
      details,
      payload: jsonEncode(data),
    );
  }
}
