import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class DriverOrderService {
  static Future<String?> _getDriverToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getDriverToken();
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Accept a new order
  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      final headers = await _getAuthHeaders();

      print('🔄 Accepting order: $orderId');
      print('🎯 POST ${AppConfig.baseUrl}/driver/orders/$orderId/accept');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/driver/orders/$orderId/accept'),
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'action': 'accept',
        }),
      );

      print('📊 Accept Order Response Status: ${response.statusCode}');
      print('📄 Accept Order Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Đã chấp nhận đơn hàng thành công',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Không thể chấp nhận đơn hàng',
          'error_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error accepting order: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Decline a new order
  static Future<Map<String, dynamic>> declineOrder(String orderId) async {
    try {
      final headers = await _getAuthHeaders();

      print('🔄 Declining order: $orderId');
      print('🎯 POST ${AppConfig.baseUrl}/driver/orders/$orderId/decline');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/driver/orders/$orderId/decline'),
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'action': 'decline',
        }),
      );

      print('📊 Decline Order Response Status: ${response.statusCode}');
      print('📄 Decline Order Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Đã từ chối đơn hàng',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Không thể từ chối đơn hàng',
          'error_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error declining order: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Accept a shared order
  static Future<Map<String, dynamic>> acceptSharedOrder(String orderId) async {
    try {
      final headers = await _getAuthHeaders();

      print('🔄 Accepting shared order: $orderId');
      print(
          '🎯 POST ${AppConfig.baseUrl}/driver/orders/$orderId/accept-shared');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/driver/orders/$orderId/accept-shared'),
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'action': 'accept_shared',
        }),
      );

      print('📊 Accept Shared Order Response Status: ${response.statusCode}');
      print('📄 Accept Shared Order Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Đã chấp nhận đơn hàng chia sẻ',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Không thể chấp nhận đơn hàng chia sẻ',
          'error_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error accepting shared order: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Get order details
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final headers = await _getAuthHeaders();

      print('🔄 Getting order details: $orderId');
      print('🎯 GET ${AppConfig.baseUrl}/driver/orders/$orderId');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/driver/orders/$orderId'),
        headers: headers,
      );

      print('📊 Get Order Details Response Status: ${response.statusCode}');
      print('📄 Get Order Details Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': 'Lấy thông tin đơn hàng thành công',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Không thể lấy thông tin đơn hàng',
          'error_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting order details: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Get driver's pending orders
  static Future<Map<String, dynamic>> getPendingOrders() async {
    try {
      final headers = await _getAuthHeaders();

      print('🔄 Getting pending orders');
      print('🎯 GET ${AppConfig.baseUrl}/driver/orders/pending');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/driver/orders/pending'),
        headers: headers,
      );

      print('📊 Get Pending Orders Response Status: ${response.statusCode}');
      print('📄 Get Pending Orders Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': 'Lấy danh sách đơn hàng thành công',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Không thể lấy danh sách đơn hàng',
          'error_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting pending orders: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}
