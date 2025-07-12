import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_token.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static FirebaseMessaging? _messaging;
  static String? _currentToken;
  static AuthToken? _authToken;

  /// Khởi tạo Firebase và FCM
  static Future<void> initialize() async {
    try {
      // Khởi tạo Firebase
      await Firebase.initializeApp();
      
      // Khởi tạo FCM
      _messaging = FirebaseMessaging.instance;
      
      // Yêu cầu quyền thông báo
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('🔔 Trạng thái quyền thông báo: ${settings.authorizationStatus}');
      
      // Lấy FCM token
      _currentToken = await _messaging!.getToken();
      print('📱 FCM Token: $_currentToken');
      
      // Thiết lập local notifications
      await _setupLocalNotifications();
      
      // Lắng nghe thông báo khi app đang mở
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Lắng nghe thông báo khi app đóng
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Lắng nghe khi app được mở từ notification
      FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
      
      print('✅ NotificationService đã khởi tạo thành công');
    } catch (e) {
      print('❌ Lỗi khởi tạo NotificationService: $e');
    }
  }

  /// Thiết lập local notifications
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Gửi FCM token lên server
  static Future<void> sendTokenToServer(AuthToken authToken) async {
    if (_currentToken == null) {
      print('❌ FCM token rỗng, không thể gửi lên server');
      return;
    }

    _authToken = authToken;
    
    try {
      print('📤 Đang gửi FCM token lên server...');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/driver/fcm/token'),
        headers: {
          'Authorization': 'Bearer ${authToken.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': _currentToken}),
      );

      print('📊 Trạng thái gửi FCM token: ${response.statusCode}');
      print('📄 Nội dung phản hồi: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Gửi FCM token lên server thành công');
      } else {
        print('❌ Gửi FCM token lên server thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi gửi FCM token lên server: $e');
    }
  }

  /// Xóa FCM token khỏi server (khi logout)
  static Future<void> removeTokenFromServer() async {
    if (_authToken == null) {
      print('❌ Thiếu Auth token, không thể xóa FCM token');
      return;
    }

    try {
      print('🗑️ Đang xóa FCM token khỏi server...');
      
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/driver/fcm/token'),
        headers: {
          'Authorization': 'Bearer ${_authToken!.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Trạng thái xóa FCM token: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Đã xóa FCM token khỏi server');
        _authToken = null;
      } else {
        print('❌ Xóa FCM token thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi xóa FCM token khỏi server: $e');
    }
  }

  /// Xử lý thông báo khi app đang mở
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Nhận thông báo foreground: ${message.data}');
    print('📝 Tiêu đề: ${message.notification?.title}');
    print('📝 Nội dung: ${message.notification?.body}');
    
    // Hiển thị local notification
    _showLocalNotification(message);
    
    // Cập nhật UI nếu cần
    _updateUI(message);
  }

  /// Xử lý thông báo khi app đóng
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Nhận thông báo background: ${message.data}');
    
    // Xử lý khi user tap vào notification
    _handleNotificationTap(message);
  }

  /// Xử lý thông báo khi app được mở từ notification
  static void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      print('📨 Nhận initial message: ${message.data}');
      _handleNotificationTap(message);
    }
  }

  /// Hiển thị local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'driver_notifications',
      'Driver Notifications',
      channelDescription: 'Thông báo cho tài xế',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Thông báo mới',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Xử lý khi user tap vào notification
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Người dùng đã nhấn vào thông báo: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(RemoteMessage(data: data));
      } catch (e) {
        print('❌ Lỗi parse notification payload: $e');
      }
    }
  }

  /// Cập nhật UI dựa trên loại thông báo
  static void _updateUI(RemoteMessage message) {
    print('🔄 Cập nhật UI cho loại thông báo: ${message.data['type']}');
    
    // Cập nhật UI dựa trên loại thông báo
    switch (message.data['type']) {
      case 'order_completed':
        // Cập nhật danh sách đơn hàng
        _refreshOrderList();
        break;
      case 'new_order_available':
        // Hiển thị đơn hàng mới
        _showNewOrder(message.data);
        break;
      case 'order_status_changed':
        // Cập nhật trạng thái đơn hàng
        _updateOrderStatus(message.data);
        break;
      default:
        print('⚠️ Không xác định loại thông báo: ${message.data['type']}');
    }
  }

  /// Xử lý khi user tap vào notification
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 Xử lý tap notification cho màn hình: ${message.data['screen']}');
    
    // Xử lý khi user tap vào notification
    switch (message.data['screen']) {
      case 'order_detail':
        // Chuyển đến trang chi tiết đơn hàng
        _navigateToOrderDetail(message.data['order_id']);
        break;
      case 'order_list':
        // Chuyển đến trang danh sách đơn hàng
        _navigateToOrderList();
        break;
      case 'home':
        // Chuyển đến trang chủ
        _navigateToHome();
        break;
      default:
        print('⚠️ Không xác định màn hình: ${message.data['screen']}');
    }
  }

  /// Refresh danh sách đơn hàng
  static void _refreshOrderList() {
    print('🔄 Làm mới danh sách đơn hàng...');
    // TODO: Thực hiện logic làm mới danh sách đơn hàng
  }

  /// Hiển thị đơn hàng mới
  static void _showNewOrder(Map<String, dynamic> data) {
    print('🆕 Hiển thị đơn hàng mới: ${data['order_id']}');
    // TODO: Thực hiện logic hiển thị đơn hàng mới
  }

  /// Cập nhật trạng thái đơn hàng
  static void _updateOrderStatus(Map<String, dynamic> data) {
    print('📊 Cập nhật trạng thái đơn hàng: ${data['order_id']} -> ${data['status']}');
    // TODO: Thực hiện logic cập nhật trạng thái đơn hàng
  }

  /// Điều hướng đến chi tiết đơn hàng
  static void _navigateToOrderDetail(dynamic orderId) {
    print('🧭 Điều hướng đến chi tiết đơn hàng: $orderId');
    // TODO: Thực hiện điều hướng đến chi tiết đơn hàng
  }

  /// Điều hướng đến danh sách đơn hàng
  static void _navigateToOrderList() {
    print('🧭 Điều hướng đến danh sách đơn hàng');
    // TODO: Thực hiện điều hướng đến danh sách đơn hàng
  }

  /// Điều hướng về trang chủ
  static void _navigateToHome() {
    print('🧭 Điều hướng về trang chủ');
    // TODO: Thực hiện điều hướng về trang chủ
  }

  /// Test gửi thông báo local
  static Future<void> testLocalNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test gửi thông báo cho tài xế',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      0,
      'Test Notification',
      'Đây là thông báo test từ Driver App',
      platformChannelSpecifics,
    );
    
    print('✅ Đã gửi test notification');
  }

  /// Lấy FCM token hiện tại
  static String? get currentToken => _currentToken;

  /// Kiểm tra xem notification service đã được khởi tạo chưa
  static bool get isInitialized => _messaging != null;
} 