import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/driver_location_service.dart';

/// Helper class to test GPS location and current-location API
class GPSTestHelper {
  /// Test getting current GPS position
  static Future<Position?> testGetCurrentPosition() async {
    try {
      print('🧪 ===== TESTING GET CURRENT GPS POSITION =====');

      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        return null;
      }

      print('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      print('✅ GPS Position obtained successfully:');
      print('📍 Latitude: ${position.latitude}');
      print('📍 Longitude: ${position.longitude}');
      print('🎯 Accuracy: ${position.accuracy} meters');
      print('⏰ Timestamp: ${position.timestamp}');
      print('📐 Altitude: ${position.altitude} meters');
      print('🧭 Heading: ${position.heading}°');
      print('⚡ Speed: ${position.speed} m/s');

      return position;
    } catch (e) {
      print('💥 GPS TEST ERROR: $e');
      return null;
    }
  }

  /// Test POST /api/driver/current-location API
  static Future<bool> testCurrentLocationAPI() async {
    try {
      print('🧪 ===== TESTING CURRENT-LOCATION API =====');

      // Get current position first
      Position? position = await testGetCurrentPosition();
      if (position == null) {
        print('❌ Cannot get GPS position for API test');
        return false;
      }

      // Get driver auth token
      final prefs = await SharedPreferences.getInstance();
      String? driverToken = prefs.getString('auth_token');

      if (driverToken == null) {
        print('❌ No driver auth token available for API test');
        return false;
      }

      print('🔑 Driver Token: ${driverToken.substring(0, 50)}...');

      // Prepare API request
      final apiUrl = '${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}';
      final requestBody = {
        'lat': position.latitude,
        'lon': position.longitude,
      };

      print('🌐 API Endpoint: $apiUrl');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $driverToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 15));

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ CURRENT-LOCATION API: SUCCESS');

        // Parse response according to API spec
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('data') &&
            responseData['data'].containsKey('location')) {
          final locationData = responseData['data']['location'];
          print('📍 Server confirmed location:');
          print('   📌 Latitude: ${locationData['lat']}');
          print('   📌 Longitude: ${locationData['lon']}');

          // Verify the coordinates match what we sent
          double sentLat = position.latitude;
          double sentLon = position.longitude;
          double receivedLat = locationData['lat'];
          double receivedLon = locationData['lon'];

          if ((sentLat - receivedLat).abs() < 0.000001 &&
              (sentLon - receivedLon).abs() < 0.000001) {
            print('✅ Location coordinates match perfectly!');
          } else {
            print('⚠️ Location coordinates mismatch:');
            print('   Sent: $sentLat, $sentLon');
            print('   Received: $receivedLat, $receivedLon');
          }
        } else {
          print('⚠️ Unexpected response format');
        }

        return true;
      } else if (response.statusCode == 401) {
        print('🔒 CURRENT-LOCATION API: UNAUTHORIZED');
        print('❌ Driver token expired or invalid');
        return false;
      } else if (response.statusCode == 422) {
        print('📋 CURRENT-LOCATION API: VALIDATION ERROR');
        final errorData = jsonDecode(response.body);
        print('🚨 Validation Errors: ${errorData['message']}');
        return false;
      } else {
        print('❌ CURRENT-LOCATION API: FAILED');
        print('🚨 Status: ${response.statusCode}');
        print('🚨 Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 CURRENT-LOCATION API TEST ERROR: $e');
      return false;
    }
  }

  /// Test using DriverLocationService
  static Future<bool> testDriverLocationService() async {
    try {
      print('🧪 ===== TESTING DRIVER LOCATION SERVICE =====');

      // Test getting current position
      Position? position = await DriverLocationService.getCurrentPosition();
      if (position == null) {
        print('❌ DriverLocationService cannot get position');
        return false;
      }

      print('✅ DriverLocationService position:');
      print('📍 ${position.latitude}, ${position.longitude}');
      print(
          '🎯 Accuracy: ${DriverLocationService.getLocationAccuracyDescription(position)}');

      // Test manual update
      print('🔄 Testing manual location update...');
      bool updateSuccess = await DriverLocationService.forceUpdateLocation();

      if (updateSuccess) {
        print('✅ DriverLocationService update: SUCCESS');
      } else {
        print('❌ DriverLocationService update: FAILED');
      }

      // Get tracking stats
      final stats = DriverLocationService.getTrackingStats();
      print('📊 Tracking Stats:');
      print('   🟢 Is Online: ${stats['isOnline']}');
      print('   🔄 Is Updating: ${stats['isUpdating']}');
      print('   ⏰ Last Update: ${stats['timeSinceLastUpdate'] ?? 'Never'}');

      return updateSuccess;
    } catch (e) {
      print('💥 DRIVER LOCATION SERVICE TEST ERROR: $e');
      return false;
    }
  }

  /// Run complete GPS and API test suite
  static Future<void> runCompleteTest() async {
    print('🚀 ===== COMPLETE GPS & API TEST SUITE =====');

    // Test 1: GPS Position
    print('\n1️⃣ Testing GPS Position...');
    Position? position = await testGetCurrentPosition();
    bool gpsSuccess = position != null;

    await Future.delayed(Duration(seconds: 2));

    // Test 2: Current-Location API
    print('\n2️⃣ Testing Current-Location API...');
    bool apiSuccess = await testCurrentLocationAPI();

    await Future.delayed(Duration(seconds: 2));

    // Test 3: Driver Location Service
    print('\n3️⃣ Testing Driver Location Service...');
    bool serviceSuccess = await testDriverLocationService();

    // Summary
    print('\n📋 ===== TEST RESULTS SUMMARY =====');
    print('GPS Position: ${gpsSuccess ? '✅ PASS' : '❌ FAIL'}');
    print('Current-Location API: ${apiSuccess ? '✅ PASS' : '❌ FAIL'}');
    print('Driver Location Service: ${serviceSuccess ? '✅ PASS' : '❌ FAIL'}');

    if (gpsSuccess && apiSuccess && serviceSuccess) {
      print('\n🎉 ALL TESTS PASSED! GPS tracking system is working correctly.');
    } else {
      print('\n⚠️ Some tests failed. Please check the issues above.');
    }

    print('==========================================');
  }

  /// Print API specification
  static void printAPISpecification() {
    print('''
🔥 ===== CURRENT-LOCATION API SPECIFICATION =====

📡 UPDATE DRIVER LOCATION
   POST /api/driver/current-location
   Headers: 
     Authorization: Bearer {driver_token}
     Content-Type: application/json
   Body: 
     {
       "lat": 10.762622,
       "lon": 106.660172
     }
   
   ✅ Success Response (200):
   {
     "data": {
       "location": {
         "lat": 10.762622,
         "lon": 106.660172
       }
     }
   }

   ❌ Validation Error (422):
   {
     "error": true,
     "message": {
       "lat": ["The lat field is required."],
       "lon": ["The lon field is required."]
     }
   }

   🔒 Unauthorized (401):
   {
     "message": "Unauthenticated."
   }

🎯 BUSINESS LOGIC:
   - Updates driver.current_location in database
   - Used for finding nearest drivers
   - Only works for authenticated & verified drivers
   - Coordinates stored as JSON: {"lat": x, "lon": y}

⚠️ IMPORTANT NOTES:
   - Requires auth:driver middleware
   - Requires profileVerified middleware  
   - Latitude/longitude must be numeric
   - Updates driver's position for order matching

===================================================
    ''');
  }
}
