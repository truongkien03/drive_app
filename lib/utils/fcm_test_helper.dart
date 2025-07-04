import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/driver_fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to test FCM API endpoints according to specification
class FCMTestHelper {
  /// Test POST /api/driver/fcm/token - Add FCM Token
  static Future<void> testAddFCMToken() async {
    try {
      print('🧪 ===== TESTING ADD FCM TOKEN API =====');

      // Get current FCM token
      String? fcmToken = await DriverFCMService.getToken();
      if (fcmToken == null) {
        print('❌ No FCM token available for testing');
        return;
      }

      // Get driver auth token
      final prefs = await SharedPreferences.getInstance();
      String? driverToken = prefs.getString('auth_token');

      if (driverToken == null) {
        print('❌ No driver auth token available for testing');
        return;
      }

      print('📱 FCM Token: ${fcmToken.substring(0, 50)}...');
      print('🔑 Driver Token: ${driverToken.substring(0, 50)}...');

      // Make API request
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverFCMToken}'),
        headers: {
          'Authorization': 'Bearer $driverToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      print('🌐 API Endpoint: ${AppConfig.baseUrl}${AppConfig.driverFCMToken}');
      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ ADD FCM TOKEN: SUCCESS');

        // Parse response according to spec
        final responseData = jsonDecode(response.body);
        print('👤 Driver ID: ${responseData['id']}');
        print('📱 Driver Name: ${responseData['name']}');
        print('📧 Driver Email: ${responseData['email']}');
        print('📞 Driver Phone: ${responseData['phone_number']}');
        print(
            '🔔 FCM Token Saved: ${responseData['fcm_token'] != null ? 'YES' : 'NO'}');
        print('🟢 Driver Status: ${responseData['status']}');
      } else {
        print('❌ ADD FCM TOKEN: FAILED');
        if (response.statusCode == 422) {
          final errorData = jsonDecode(response.body);
          print('🚨 Validation Errors: ${errorData['message']}');
        }
      }
    } catch (e) {
      print('💥 ADD FCM TOKEN TEST ERROR: $e');
    }
  }

  /// Test DELETE /api/driver/fcm/token - Remove FCM Token
  static Future<void> testRemoveFCMToken() async {
    try {
      print('🧪 ===== TESTING REMOVE FCM TOKEN API =====');

      // Get driver auth token
      final prefs = await SharedPreferences.getInstance();
      String? driverToken = prefs.getString('auth_token');

      if (driverToken == null) {
        print('❌ No driver auth token available for testing');
        return;
      }

      print('🔑 Driver Token: ${driverToken.substring(0, 50)}...');

      // Make API request
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverFCMToken}'),
        headers: {
          'Authorization': 'Bearer $driverToken',
          'Content-Type': 'application/json',
        },
      );

      print('🌐 API Endpoint: ${AppConfig.baseUrl}${AppConfig.driverFCMToken}');
      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ REMOVE FCM TOKEN: SUCCESS');

        // Parse response according to spec
        final responseData = jsonDecode(response.body);
        print('👤 Driver ID: ${responseData['id']}');
        print('📱 Driver Name: ${responseData['name']}');
        print('📧 Driver Email: ${responseData['email']}');
        print('📞 Driver Phone: ${responseData['phone_number']}');
        print(
            '🔔 FCM Token Removed: ${responseData['fcm_token'] == null ? 'YES' : 'NO'}');
        print('🟢 Driver Status: ${responseData['status']}');
      } else {
        print('❌ REMOVE FCM TOKEN: FAILED');
      }
    } catch (e) {
      print('💥 REMOVE FCM TOKEN TEST ERROR: $e');
    }
  }

  /// Test complete FCM flow: Add -> Remove -> Add again
  static Future<void> testCompleteFCMFlow() async {
    print('🚀 ===== TESTING COMPLETE FCM FLOW =====');

    // Step 1: Add FCM Token
    await testAddFCMToken();

    print('\n⏳ Waiting 2 seconds...\n');
    await Future.delayed(Duration(seconds: 2));

    // Step 2: Remove FCM Token
    await testRemoveFCMToken();

    print('\n⏳ Waiting 2 seconds...\n');
    await Future.delayed(Duration(seconds: 2));

    // Step 3: Add FCM Token again
    await testAddFCMToken();

    print('🏁 ===== FCM FLOW TEST COMPLETED =====');
  }

  /// Simulate notification payload according to spec
  static Map<String, dynamic> getMockNotificationPayload({
    required String type,
    required String orderId,
  }) {
    switch (type) {
      case 'NewOrder':
        return {
          'title': '🚚 Đơn hàng mới!',
          'body': 'Bạn có đơn hàng mới cần xác nhận. Phí: 45,000đ',
          'data': {
            'key': 'NewOder', // Note: typo in spec
            'link': 'driver://AwaitAcceptOder', // Note: typo in spec
            'oderId': orderId, // Note: typo in spec
          }
        };

      case 'OrderCancelled':
        return {
          'title': '❌ Đơn hàng bị hủy',
          'body': 'Đơn hàng #$orderId đã bị hủy bởi khách hàng',
          'data': {
            'key': 'OrderCancelled',
            'orderId': orderId,
          }
        };

      case 'OrderShared':
        return {
          'title': '🤝 Đơn hàng chia sẻ',
          'body': 'Bạn được mời nhận đơn hàng #$orderId',
          'data': {
            'key': 'OrderShared',
            'link': 'driver://OrderShared',
            'orderId': orderId,
          }
        };

      default:
        return {};
    }
  }

  /// Print API specification summary
  static void printAPISpecification() {
    print('''
🔥 ===== FCM API SPECIFICATION FOR DRIVER =====

📡 1. ADD FCM TOKEN
   POST /api/driver/fcm/token
   Headers: Authorization: Bearer {driver_token}
   Body: {"fcm_token": "firebase_token_string"}
   
   Success Response (200):
   {
     "id": 1,
     "name": "Nguyễn Văn A",
     "email": "driver@example.com",
     "phone_number": "0987654321",
     "fcm_token": "firebase_token_string",
     "status": "free",
     "current_location": {"lat": 10.762622, "lon": 106.660172},
     "created_at": "2025-07-01T10:30:00.000000Z",
     "updated_at": "2025-07-01T10:35:00.000000Z"
   }

🗑️ 2. REMOVE FCM TOKEN
   DELETE /api/driver/fcm/token
   Headers: Authorization: Bearer {driver_token}
   
   Success Response (200):
   {
     "id": 1,
     "name": "Nguyễn Văn A", 
     "email": "driver@example.com",
     "phone_number": "0987654321",
     "fcm_token": null,
     "status": "free",
     "created_at": "2025-07-01T10:30:00.000000Z",
     "updated_at": "2025-07-01T10:40:00.000000Z"
   }

🔔 3. NOTIFICATION PAYLOAD EXAMPLES
   New Order: {"key": "NewOder", "link": "driver://AwaitAcceptOder", "oderId": "123"}
   Order Cancelled: {"key": "OrderCancelled", "orderId": "123"}
   Order Shared: {"key": "OrderShared", "link": "driver://OrderShared", "orderId": "123"}

🎯 4. BACKEND TOPIC SUBSCRIPTION
   - When ADD: Subscribe to "driver-{driver_id}"
   - When REMOVE: Unsubscribe from "driver-{driver_id}"

===================================================
    ''');
  }
}
