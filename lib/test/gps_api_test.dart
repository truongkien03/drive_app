import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script for GPS and API integration
class GPSAPITest {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String currentLocationEndpoint = '/driver/current-location';

  /// Test sending location to server
  static Future<void> testLocationAPI({
    required String token,
    required double lat,
    required double lon,
  }) async {
    print('🧪 Testing Location API...');
    print('📍 Sending location: $lat, $lon');
    print('🔑 Using token: ${token.substring(0, 20)}...');

    try {
      final url = '$baseUrl$currentLocationEndpoint';
      print('🌐 URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'lat': lat,
              'lon': lon,
            }),
          )
          .timeout(Duration(seconds: 15));

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ SUCCESS: Location updated successfully');
        print(
            '📍 Server confirmed location: ${responseData['data']['location']}');
      } else if (response.statusCode == 401) {
        print('🔒 ERROR: Unauthorized - Token expired or invalid');
        print('💡 Suggestion: Check if driver is logged in and token is valid');
      } else if (response.statusCode == 422) {
        print('❌ ERROR: Validation failed');
        print('💡 Response: ${response.body}');
      } else {
        print('❌ ERROR: Server error (${response.statusCode})');
        print('💡 Response: ${response.body}');
      }
    } catch (e) {
      print('💥 EXCEPTION: Network error - $e');
      print('💡 Suggestion: Check internet connection and server status');
    }
  }

  /// Test authentication endpoints
  static Future<void> testAuth({
    required String phoneNumber,
  }) async {
    print('🧪 Testing Authentication...');
    print('📱 Phone: $phoneNumber');

    try {
      // Test login OTP endpoint
      final loginOtpUrl = '$baseUrl/driver/login/otp';
      print('🌐 Testing: $loginOtpUrl');

      final response = await http
          .post(
            Uri.parse(loginOtpUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'phone_number': phoneNumber,
            }),
          )
          .timeout(Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ SUCCESS: OTP sent successfully');
      } else {
        print('❌ ERROR: Failed to send OTP');
      }
    } catch (e) {
      print('💥 EXCEPTION: $e');
    }
  }

  /// Test server connectivity
  static Future<void> testConnectivity() async {
    print('🧪 Testing Server Connectivity...');

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        print('✅ SUCCESS: Server is reachable');
      } else {
        print(
            '⚠️ WARNING: Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      print('💥 EXCEPTION: Server unreachable - $e');
      print('💡 Suggestions:');
      print('  - Check if backend server is running');
      print('  - Verify the base URL: $baseUrl');
      print('  - Check network connection');
    }
  }

  /// Print API documentation
  static void printAPIDocumentation() {
    print('''
📋 API DOCUMENTATION

🔗 Endpoint: POST /api/driver/current-location
🛡️  Auth: Bearer token required
📋 Headers:
   - Authorization: Bearer {token}
   - Content-Type: application/json
   - Accept: application/json

📨 Request Body:
{
  "lat": 10.762622,   // required, numeric
  "lon": 106.660172   // required, numeric
}

📤 Success Response (200):
{
  "data": {
    "location": {
      "lat": 10.762622,
      "lon": 106.660172
    }
  }
}

❌ Error Responses:
- 401: Unauthorized (invalid token)
- 422: Validation error (invalid lat/lon)
- 500: Server error

💡 Usage Notes:
- Only authenticated drivers can update location
- Driver profile must be verified
- Location is stored in database as JSON
- Used for finding nearest drivers for orders
    ''');
  }

  /// Run comprehensive test suite
  static Future<void> runTestSuite({
    String? token,
    String? phoneNumber,
    double? testLat,
    double? testLon,
  }) async {
    print('🚀 Starting GPS API Test Suite...');
    print('=' * 50);

    // Print API documentation
    printAPIDocumentation();
    print('=' * 50);

    // Test 1: Server connectivity
    await testConnectivity();
    print('-' * 30);

    // Test 2: Authentication (if phone provided)
    if (phoneNumber != null) {
      await testAuth(phoneNumber: phoneNumber);
      print('-' * 30);
    }

    // Test 3: Location API (if token and coordinates provided)
    if (token != null && testLat != null && testLon != null) {
      await testLocationAPI(
        token: token,
        lat: testLat,
        lon: testLon,
      );
      print('-' * 30);
    }

    print('🏁 Test Suite Completed');
    print('=' * 50);
  }
}

/// Example usage
void main() async {
  // Example test calls
  print('📱 GPS API Test Script');

  // Test server connectivity
  await GPSAPITest.testConnectivity();

  // Example with sample data (replace with real values)
  await GPSAPITest.runTestSuite(
    phoneNumber: '0123456789',
    token: 'your_actual_bearer_token_here',
    testLat: 10.762622,
    testLon: 106.660172,
  );
}
