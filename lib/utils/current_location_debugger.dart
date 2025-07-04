import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'gps_test_helper.dart';

/// Debug helper for current_location null issues
class CurrentLocationDebugger {
  /// Check driver profile and current_location status
  static Future<void> debugCurrentLocationIssue() async {
    print('🔍 ===== DEBUGGING CURRENT_LOCATION NULL ISSUE =====');

    try {
      // Get driver auth token
      final prefs = await SharedPreferences.getInstance();
      String? driverToken = prefs.getString('auth_token');

      if (driverToken == null) {
        print('❌ No driver auth token found');
        print('💡 Solution: Please login again');
        return;
      }

      print('🔑 Driver Token: ${driverToken.substring(0, 50)}...');

      // Get driver profile to check current_location
      await _checkDriverProfile(driverToken);

      // Test location update API
      await _testLocationUpdate(driverToken);
    } catch (e) {
      print('💥 Error during debugging: $e');
    }

    print('🔍 ===== DEBUG COMPLETED =====');
  }

  /// Check driver profile endpoint
  static Future<void> _checkDriverProfile(String token) async {
    try {
      print('\n📱 Checking driver profile...');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfile}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('📊 Profile Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        print('✅ Driver Profile Retrieved Successfully');

        // Check current_location field
        if (profileData.containsKey('current_location')) {
          final currentLocation = profileData['current_location'];

          if (currentLocation == null) {
            print('❌ ISSUE FOUND: current_location is NULL');
            print(
                '💡 This means driver has never updated location or it was reset');
            _suggestLocationFix();
          } else if (currentLocation is Map) {
            print('✅ current_location exists:');
            print('   📍 Latitude: ${currentLocation['lat']}');
            print('   📍 Longitude: ${currentLocation['lon']}');
          } else {
            print(
                '⚠️ current_location has unexpected format: $currentLocation');
          }
        } else {
          print('❌ current_location field not found in profile');
        }

        // Show other driver info
        print('\n👤 Driver Info:');
        print('   ID: ${profileData['id']}');
        print('   Name: ${profileData['name'] ?? 'N/A'}');
        print('   Phone: ${profileData['phone_number'] ?? 'N/A'}');
        print('   Status: ${_getStatusText(profileData['status'])}');
        print(
            '   Profile Complete: ${profileData['is_profile_complete'] ?? false}');
        print(
            '   FCM Token: ${profileData['fcm_token'] != null ? 'Set' : 'Not Set'}');
      } else if (response.statusCode == 401) {
        print('🔒 Unauthorized - Token expired');
        print('💡 Solution: Please login again');
      } else {
        print('❌ Failed to get profile: ${response.statusCode}');
        print('📄 Response: ${response.body}');
      }
    } catch (e) {
      print('💥 Error checking profile: $e');
    }
  }

  /// Test location update to fix null current_location
  static Future<void> _testLocationUpdate(String token) async {
    try {
      print('\n🧪 Testing location update to fix null issue...');

      // Use a sample location (Hanoi center)
      const double testLat = 21.028511;
      const double testLon = 105.854202;

      print('📍 Sending test location: $testLat, $testLon');

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'lat': testLat,
              'lon': testLon,
            }),
          )
          .timeout(Duration(seconds: 10));

      print('📊 Update Response Status: ${response.statusCode}');
      print('📄 Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Location update SUCCESS');

        if (responseData.containsKey('data') &&
            responseData['data'].containsKey('location')) {
          final location = responseData['data']['location'];
          print('✅ Server confirmed location update:');
          print('   📍 Latitude: ${location['lat']}');
          print('   📍 Longitude: ${location['lon']}');
          print('💡 current_location should no longer be null');
        }

        // Verify by checking profile again
        print('\n🔄 Verifying fix by checking profile again...');
        await Future.delayed(Duration(seconds: 1));
        await _checkDriverProfile(token);
      } else if (response.statusCode == 401) {
        print('🔒 Unauthorized - Cannot update location');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        print('❌ Validation Error: ${errorData['message']}');
      } else {
        print('❌ Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error testing location update: $e');
    }
  }

  /// Suggest solutions for fixing current_location null
  static void _suggestLocationFix() {
    print('\n💡 ===== SOLUTIONS FOR CURRENT_LOCATION NULL =====');
    print('1. 🎯 IMMEDIATE FIX:');
    print('   • Open GPS Test screen');
    print('   • Tap "Lấy vị trí GPS" then "Gửi lên Server"');
    print('   • Or use "Test API" button');

    print('\n2. 🤖 AUTOMATIC FIX:');
    print('   • Set driver status to Online');
    print('   • GPS tracking will start automatically');
    print('   • First location will be sent to server');

    print('\n3. 🗺️ MAP FIX:');
    print('   • Open "GPS Tracking Map" screen');
    print('   • Tap "Bật Online" button');
    print('   • Location will be updated automatically');

    print('\n4. 🔧 MANUAL API CALL:');
    print('   • Call: POST /api/driver/current-location');
    print('   • Body: {"lat": your_lat, "lon": your_lon}');
    print('   • Headers: Authorization: Bearer {token}');

    print('\n⚠️ NOTE: Driver must be ONLINE and have GPS permission');
    print('🎯 After any fix, current_location will contain coordinates');
  }

  /// Get status text from status code
  static String _getStatusText(dynamic status) {
    if (status == null) return 'Unknown';

    switch (status) {
      case 0:
        return 'OFFLINE';
      case 1:
        return 'FREE/ONLINE';
      case 2:
        return 'BUSY';
      case 3:
        return 'SUSPENDED';
      default:
        return 'Unknown ($status)';
    }
  }

  /// Quick fix: Send current GPS location to server
  static Future<bool> quickFixCurrentLocation() async {
    try {
      print('🚀 ===== QUICK FIX: UPDATING CURRENT LOCATION =====');

      // Get current position
      print('📍 Getting current GPS position...');
      final position = await GPSTestHelper.testGetCurrentPosition();

      if (position == null) {
        print('❌ Cannot get GPS position');
        return false;
      }

      // Send to server
      print('🌐 Sending location to server...');
      final success = await GPSTestHelper.testCurrentLocationAPI();

      if (success) {
        print('✅ QUICK FIX SUCCESSFUL!');
        print('💡 current_location should now be set');
        return true;
      } else {
        print('❌ Quick fix failed');
        return false;
      }
    } catch (e) {
      print('💥 Quick fix error: $e');
      return false;
    }
  }

  /// Print troubleshooting guide
  static void printTroubleshootingGuide() {
    print('''
🔧 ===== CURRENT_LOCATION NULL TROUBLESHOOTING =====

🔍 WHAT IS current_location?
   • JSON field in driver table: {"lat": x, "lon": y}
   • Updated by POST /api/driver/current-location
   • Used for finding nearest drivers
   • NULL means driver never sent location

❌ WHY IS IT NULL?
   1. New driver account (never updated location)
   2. Database was reset/migrated
   3. Location updates failed due to errors
   4. Driver always stayed offline
   5. GPS permissions denied

✅ HOW TO FIX:
   1. QUICK: Use GPS Test screen → send location
   2. AUTO: Set driver online → GPS auto-tracks
   3. MANUAL: Call update API with lat/lon
   4. MAP: Use GPS Tracking Map → auto-update

🧪 HOW TO VERIFY FIX:
   1. Check driver profile API response
   2. Look for current_location: {"lat": x, "lon": y}
   3. Should not be null anymore

⚠️ REQUIREMENTS:
   • Driver must be authenticated
   • Profile must be verified  
   • GPS permission granted
   • Location services enabled
   • Internet connection active

🎯 PREVENTION:
   • Always update location when driver goes online
   • Implement retry mechanism for failed updates
   • Cache location offline, send when back online
   • Regular health checks for location status

====================================================
    ''');
  }
}
