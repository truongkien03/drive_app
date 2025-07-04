import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Service to manage driver location updates
class DriverLocationService {
  static Timer? _locationTimer;
  static Position? _lastKnownPosition;
  static DateTime? _lastUpdateTime;
  static bool _isOnline = false;
  static bool _isUpdating = false;

  // Configuration constants
  static const int _updateIntervalSeconds = 30;
  static const double _minimumDistanceMeters = 100.0;
  static const int _maxRetryAttempts = 3;
  static const int _retryDelaySeconds = 5;

  /// Initialize location service
  static Future<void> initialize() async {
    try {
      print('📍 Initializing DriverLocationService...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return;
      }

      print('✅ DriverLocationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing DriverLocationService: $e');
    }
  }

  /// Start location tracking when driver goes online
  static Future<void> startLocationTracking() async {
    if (_isOnline) {
      print('⚠️ Location tracking already started');
      return;
    }

    try {
      print('🟢 Starting location tracking...');
      _isOnline = true;

      // Get initial location and send immediately
      await _getCurrentLocationAndUpdate();

      // Start periodic updates
      _locationTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (timer) async {
          if (_isOnline) {
            await _getCurrentLocationAndUpdate();
          } else {
            timer.cancel();
          }
        },
      );

      print('✅ Location tracking started successfully');
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      _isOnline = false;
    }
  }

  /// Stop location tracking when driver goes offline
  static void stopLocationTracking() {
    print('🔴 Stopping location tracking...');

    _isOnline = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    print('✅ Location tracking stopped');
  }

  /// Get current location and update server
  static Future<void> _getCurrentLocationAndUpdate() async {
    if (_isUpdating) {
      print('⚠️ Location update already in progress, skipping...');
      return;
    }

    try {
      _isUpdating = true;
      print('📍 Getting current location...');

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print('📍 Current position: ${position.latitude}, ${position.longitude}');

      // Check if position has significantly changed
      if (_shouldUpdateLocation(position)) {
        await _updateLocationOnServer(position);
        _lastKnownPosition = position;
        _lastUpdateTime = DateTime.now();
      } else {
        print('📍 Position not changed significantly, skipping update');
      }
    } catch (e) {
      print('❌ Error getting current location: $e');

      // If we can't get current location, try to use last known position
      if (_lastKnownPosition != null) {
        print('📍 Using last known position for update');
        await _updateLocationOnServer(_lastKnownPosition!);
      }
    } finally {
      _isUpdating = false;
    }
  }

  /// Check if location should be updated based on distance and time
  static bool _shouldUpdateLocation(Position newPosition) {
    // Always update if this is the first position
    if (_lastKnownPosition == null) {
      print('📍 First position update');
      return true;
    }

    // Calculate distance from last known position
    double distanceInMeters = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    print(
        '📍 Distance from last position: ${distanceInMeters.toStringAsFixed(2)}m');

    // Update if distance is significant
    if (distanceInMeters >= _minimumDistanceMeters) {
      print('📍 Distance threshold reached, updating location');
      return true;
    }

    // Update if too much time has passed (force update every 5 minutes)
    if (_lastUpdateTime != null) {
      int minutesSinceLastUpdate =
          DateTime.now().difference(_lastUpdateTime!).inMinutes;
      if (minutesSinceLastUpdate >= 5) {
        print(
            '📍 Time threshold reached (${minutesSinceLastUpdate}min), updating location');
        return true;
      }
    }

    return false;
  }

  /// Update location on server with retry mechanism
  static Future<void> _updateLocationOnServer(Position position) async {
    int retryCount = 0;

    while (retryCount < _maxRetryAttempts) {
      try {
        print('🌐 Updating location on server (attempt ${retryCount + 1})...');

        final response = await _makeLocationUpdateRequest(position);

        if (response.statusCode == 200) {
          print('✅ Location updated successfully on server');
          final responseData = jsonDecode(response.body);

          // Check if response has the expected format
          if (responseData.containsKey('data') &&
              responseData['data'].containsKey('location')) {
            final locationData = responseData['data']['location'];
            print(
                '📍 Server confirmed location: lat=${locationData['lat']}, lon=${locationData['lon']}');
          } else {
            print('⚠️ Unexpected response format: ${responseData}');
          }

          print('✅ current_location should now be set (no longer null)');
          return;
        } else if (response.statusCode == 401) {
          print('🔒 Unauthorized - driver token expired');
          // TODO: Trigger re-login
          return;
        } else if (response.statusCode == 422) {
          print('❌ Invalid location data: ${response.body}');
          return;
        } else {
          print('⚠️ Server error (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('❌ Network error updating location: $e');
      }

      retryCount++;
      if (retryCount < _maxRetryAttempts) {
        print('⏳ Retrying in ${_retryDelaySeconds} seconds...');
        await Future.delayed(Duration(seconds: _retryDelaySeconds));
      }
    }

    print('❌ Failed to update location after $retryCount attempts');
  }

  /// Make HTTP request to update location
  static Future<http.Response> _makeLocationUpdateRequest(
      Position position) async {
    final driverToken = await _getDriverToken();
    if (driverToken == null) {
      throw Exception('No driver auth token available');
    }

    return await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}'),
          headers: {
            'Authorization': 'Bearer $driverToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'lat': position.latitude,
            'lon': position.longitude,
          }),
        )
        .timeout(Duration(seconds: 10));
  }

  /// Get driver auth token from storage
  static Future<String?> _getDriverToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Manual location update (called when driver accepts order)
  static Future<void> updateLocationNow() async {
    if (!_isOnline) {
      print('⚠️ Driver is offline, cannot update location');
      return;
    }

    print('📍 Manual location update requested...');
    await _getCurrentLocationAndUpdate();
  }

  /// Force location update regardless of online status (for testing)
  static Future<bool> forceUpdateLocation() async {
    try {
      print('🔄 Force updating location...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final response = await _makeLocationUpdateRequest(position);

      if (response.statusCode == 200) {
        print('✅ Force location update successful');
        _lastKnownPosition = position;
        _lastUpdateTime = DateTime.now();
        return true;
      } else {
        print('❌ Force location update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Force location update error: $e');
      return false;
    }
  }

  /// Get current position without updating server
  static Future<Position?> getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('❌ Error getting current position: $e');
      return _lastKnownPosition;
    }
  }

  /// Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      return serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      print('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Get location permission status
  static Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Get last known position
  static Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if currently tracking location
  static bool get isTracking => _isOnline;

  /// Get time since last update
  static String? get timeSinceLastUpdate {
    if (_lastUpdateTime == null) return null;

    final duration = DateTime.now().difference(_lastUpdateTime!);
    if (duration.inMinutes < 1) {
      return 'Vừa xong';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} phút trước';
    } else {
      return '${duration.inHours} giờ trước';
    }
  }

  /// Get location accuracy description
  static String getLocationAccuracyDescription(Position position) {
    if (position.accuracy <= 5) {
      return 'Rất chính xác';
    } else if (position.accuracy <= 10) {
      return 'Chính xác';
    } else if (position.accuracy <= 20) {
      return 'Tương đối chính xác';
    } else {
      return 'Ít chính xác';
    }
  }

  /// Calculate distance between two positions
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Format coordinates for display
  static String formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  /// Dispose resources
  static void dispose() {
    stopLocationTracking();
    _lastKnownPosition = null;
    _lastUpdateTime = null;
  }

  /// Get tracking statistics
  static Map<String, dynamic> getTrackingStats() {
    return {
      'isOnline': _isOnline,
      'isUpdating': _isUpdating,
      'lastPosition': _lastKnownPosition != null
          ? {
              'lat': _lastKnownPosition!.latitude,
              'lon': _lastKnownPosition!.longitude,
              'accuracy': _lastKnownPosition!.accuracy,
              'timestamp': _lastKnownPosition!.timestamp.toIso8601String(),
            }
          : null,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'timeSinceLastUpdate': timeSinceLastUpdate,
    };
  }

  /// Enable/disable debug logging
  static bool _debugMode = true;
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  static void _debugPrint(String message) {
    if (_debugMode) {
      print(message);
    }
  }
}
