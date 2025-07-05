import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsKey = 'local_notifications';

  // Get driver auth token
  Future<String?> _getDriverToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getDriverToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Lấy danh sách thông báo từ server
  Future<ApiResponse<List<DriverNotification>>> getNotifications() async {
    try {
      print('📱 Getting notifications from server...');

      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) {
        print('❌ No auth token found');
        return ApiResponse.error('No authentication token found');
      }

      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/notifications'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('📊 Notifications Response Status: ${response.statusCode}');
      print('📄 Notifications Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);

          if (responseData['data'] != null) {
            final List<dynamic> notificationsJson = responseData['data'];
            final notifications = notificationsJson
                .map((json) => DriverNotification.fromJson(json))
                .toList();

            print('✅ Got ${notifications.length} notifications from server');

            // Save to local storage for offline access
            await _saveNotificationsToLocal(notifications);

            return ApiResponse.success(notifications);
          } else {
            print('⚠️ No data field in response');
            return ApiResponse.success([]);
          }
        } else {
          print('⚠️ Empty response body');
          return ApiResponse.success([]);
        }
      } else if (response.statusCode == 401) {
        print('🔒 Unauthorized - token may be expired');
        return ApiResponse.error('Unauthorized - Please login again');
      } else {
        print('❌ Server error: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData, null);
        }
        return ApiResponse.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception getting notifications: $e');

      // Return local notifications if network fails
      final localNotifications = await _getLocalNotifications();
      if (localNotifications.isNotEmpty) {
        print('📱 Returning ${localNotifications.length} local notifications');
        return ApiResponse.success(localNotifications);
      }

      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Lưu notification local (từ FCM hoặc server)
  Future<void> addLocalNotification(DriverNotification notification) async {
    try {
      final existingNotifications = await _getLocalNotifications();

      // Tránh duplicate
      if (!existingNotifications.any((n) => n.id == notification.id)) {
        existingNotifications.insert(0, notification); // Add to top

        // Giới hạn 100 notifications cục bộ
        if (existingNotifications.length > 100) {
          existingNotifications.removeRange(100, existingNotifications.length);
        }

        await _saveNotificationsToLocal(existingNotifications);
        print('✅ Added local notification: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error saving local notification: $e');
    }
  }

  /// Lấy notifications từ local storage
  Future<List<DriverNotification>> _getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((json) => DriverNotification.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('❌ Error loading local notifications: $e');
    }
    return [];
  }

  /// Lưu notifications vào local storage
  Future<void> _saveNotificationsToLocal(
      List<DriverNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_notificationsKey, jsonString);
    } catch (e) {
      print('❌ Error saving notifications to local: $e');
    }
  }

  /// Đánh dấu notification đã đọc (local only)
  Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await _getLocalNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(
          readAt: DateTime.now(),
        );
        await _saveNotificationsToLocal(notifications);
        print('✅ Marked notification as read: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Xóa tất cả notifications cục bộ
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      print('✅ Cleared all local notifications');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Đếm số notification chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final notifications = await _getLocalNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Tạo notification từ FCM message data
  DriverNotification createFromFCMData(Map<String, dynamic> data,
      {String? title, String? body}) {
    final actionType = data['action_type']?.toString() ?? '';
    final orderId = data['order_id']?.toString() ?? '';

    String notificationTitle = title ?? _getDefaultTitle(actionType);
    String notificationMessage =
        body ?? _getDefaultMessage(actionType, orderId, data);

    return DriverNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'FCMNotification',
      title: notificationTitle,
      message: notificationMessage,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  /// Lấy title mặc định theo action type
  String _getDefaultTitle(String actionType) {
    switch (actionType) {
      case 'new_order':
        return '🚚 Đơn hàng mới';
      case 'order_cancelled':
        return '❌ Đơn hàng bị hủy';
      case 'order_shared':
        return '🤝 Đơn hàng chia sẻ';
      default:
        return '🔔 Thông báo';
    }
  }

  /// Lấy message mặc định theo action type
  String _getDefaultMessage(
      String actionType, String orderId, Map<String, dynamic> data) {
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

  /// Test method để tạo notification giả lập
  Future<void> createTestNotification(String type) async {
    final testData = <String, dynamic>{
      'action_type': type,
      'order_id': '123',
      'distance': '2.5',
      'shared_by': '456',
    };

    final notification = createFromFCMData(testData);
    await addLocalNotification(notification);
    print('✅ Created test notification: $type');
  }
}
