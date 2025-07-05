import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  bool _isTrackingLocation = false;
  Position? _lastKnownPosition;
  final ApiService _apiService = ApiService();

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  int _consecutiveFailures = 0;

  // Location update interval configuration
  Duration _updateInterval = const Duration(minutes: 1); // Default: 1 minute

  // Authentication status tracking
  bool _isAuthenticationValid = true;
  DateTime? _lastAuthError;

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    try {
      print('🗺️ Checking location permissions...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('📱 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return false;
      }

      print('✅ Location permission granted: $permission');
      return true;
    } catch (e) {
      print('💥 Error checking location permission: $e');
      return false;
    }
  }

  /// Get current location once with timeout
  Future<Position?> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      if (!await checkLocationPermission()) {
        print('❌ No location permission');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          print('⏰ Location request timed out after 30 seconds');
          throw TimeoutException(
              'Location request timed out', const Duration(seconds: 30));
        },
      );

      _lastKnownPosition = position;
      print(
          '✅ Location obtained: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
      return position;
    } on TimeoutException catch (e) {
      print('⏰ Location timeout: $e');

      // Try to get last known position as fallback
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print(
              '🔄 Using last known position as fallback: ${lastPosition.latitude}, ${lastPosition.longitude}');
          return lastPosition;
        }
      } catch (e) {
        print('❌ Could not get last known position: $e');
      }

      return null;
    } catch (e) {
      print('💥 Error getting current location: $e');
      return null;
    }
  }

  /// Start tracking location and sending to server
  Future<void> startLocationTracking() async {
    if (_isTrackingLocation) {
      print('⚠️ Location tracking already started');
      return;
    }

    try {
      print('🚀 Starting location tracking...');

      if (!await checkLocationPermission()) {
        print('❌ Cannot start location tracking - no permission');
        return;
      }

      _isTrackingLocation = true;

      // Get initial location
      final initialPosition = await getCurrentLocation();
      if (initialPosition != null) {
        await _sendLocationToServer(
          initialPosition.latitude,
          initialPosition.longitude,
        );
      }

      // Start periodic location updates
      _locationTimer = Timer.periodic(
        _updateInterval, // Update with configurable interval
        (timer) async {
          if (!_isTrackingLocation) {
            timer.cancel();
            return;
          }

          await _updateLocation();
        },
      );

      print('✅ Location tracking started');
    } catch (e) {
      print('💥 Error starting location tracking: $e');
      _isTrackingLocation = false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    print('🛑 Stopping location tracking...');

    _isTrackingLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    print('✅ Location tracking stopped');
  }

  /// Update location and send to server
  Future<void> _updateLocation() async {
    try {
      if (!_isTrackingLocation) return;

      print('🔄 Updating location...');

      final position = await getCurrentLocation();
      if (position != null) {
        await _sendLocationToServer(position.latitude, position.longitude);
      }
    } catch (e) {
      print('💥 Error updating location: $e');
    }
  }

  /// Send location to server via API with retry mechanism
  Future<void> _sendLocationToServer(double lat, double lon) async {
    // Check if we have authentication token
    if (_apiService.token == null) {
      print('🔒 No authentication token available - cannot send location');
      _consecutiveFailures++;
      return;
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print(
            '📤 Sending location to server (attempt $attempt/$_maxRetries): $lat, $lon');
        print('🔑 Using token: ${_apiService.token?.substring(0, 20)}...');

        final response = await _apiService.updateDriverLocation(lat, lon);

        print('📊 API Response - Success: ${response.success}');
        print('📄 API Response - Message: ${response.message}');
        print('📄 API Response - Data: ${response.data}');

        if (response.success) {
          print('✅ Location sent to server successfully');
          _consecutiveFailures = 0; // Reset failure counter
          _isAuthenticationValid = true; // Reset auth status
          _lastKnownPosition = Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          return; // Success, exit retry loop
        } else {
          print('❌ Failed to send location to server: ${response.message}');
          print('🔍 Response error details: ${response.data}');

          // Check if it's an auth error (don't retry for auth errors)
          if (response.message?.contains('Unauthenticated') == true ||
              response.message?.contains('401') == true ||
              response.message?.contains('Unauthorized') == true) {
            print('🔒 AUTHENTICATION ERROR DETECTED!');
            print('💡 This means the driver token is invalid or expired');
            print('🔄 Driver needs to login again to get a new token');

            _isAuthenticationValid = false;
            _lastAuthError = DateTime.now();
            _consecutiveFailures++;

            // Stop location tracking when auth fails
            print(
                '⏹️ Stopping location tracking due to authentication failure');
            stopLocationTracking();
            return;
          }
        }
      } catch (e) {
        print('💥 Error sending location to server (attempt $attempt): $e');
        print('🔍 Error type: ${e.runtimeType}');
        print('🔍 Error details: ${e.toString()}');
      }

      // If this wasn't the last attempt, wait before retrying
      if (attempt < _maxRetries) {
        print('⏳ Waiting ${_retryDelay.inSeconds}s before retry...');
        await Future.delayed(_retryDelay);
      }
    }

    // All retries failed
    _consecutiveFailures++;
    print('❌ Failed to update location after $_maxRetries attempts');
    print('🔍 Total consecutive failures: $_consecutiveFailures');
    print('💡 Common causes:');
    print('   - No internet connection');
    print('   - Server is down');
    print('   - Authentication token expired');
    print('   - API endpoint changed');

    // If too many consecutive failures, stop tracking temporarily
    if (_consecutiveFailures >= 5) {
      print(
          '🚨 Too many consecutive failures (${_consecutiveFailures}), stopping location tracking temporarily');
      _temporarilyStopTracking();
    }
  }

  /// Temporarily stop tracking due to failures
  void _temporarilyStopTracking() {
    print('⏸️ Temporarily stopping location tracking due to failures...');
    _isTrackingLocation = false;
    _locationTimer?.cancel();

    // Restart tracking after 5 minutes
    Timer(const Duration(minutes: 5), () {
      if (!_isTrackingLocation) {
        print('🔄 Attempting to restart location tracking...');
        _consecutiveFailures = 0; // Reset counter
        startLocationTracking();
      }
    });
  }

  /// Force update location immediately
  Future<void> forceUpdateLocation() async {
    print('⚡ Force updating location...');
    await _updateLocation();
  }

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if currently tracking location
  bool get isTrackingLocation => _isTrackingLocation;

  /// Check if authentication is valid
  bool get isAuthenticationValid => _isAuthenticationValid;

  /// Get last authentication error time
  DateTime? get lastAuthError => _lastAuthError;

  /// Reset authentication status (call this after re-login)
  void resetAuthenticationStatus() {
    _isAuthenticationValid = true;
    _lastAuthError = null;
    _consecutiveFailures = 0;
    print(
        '🔄 Authentication status reset - ready to restart location tracking');
  }

  /// Get location with better accuracy (for important operations)
  Future<Position?> getHighAccuracyLocation() async {
    try {
      print('🎯 Getting high accuracy location...');

      if (!await checkLocationPermission()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print(
          '✅ High accuracy location: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
      return position;
    } catch (e) {
      print('💥 Error getting high accuracy location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if driver has moved significantly
  bool hasMovedSignificantly(Position newPosition) {
    if (_lastKnownPosition == null) return true;

    final distance = calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // Consider significant if moved more than 50 meters
    return distance > 50;
  }

  /// Get connection status and statistics
  Map<String, dynamic> getLocationStats() {
    return {
      'isTracking': _isTrackingLocation,
      'lastKnownPosition': _lastKnownPosition != null
          ? {
              'lat': _lastKnownPosition!.latitude,
              'lon': _lastKnownPosition!.longitude,
              'timestamp': _lastKnownPosition!.timestamp.toIso8601String(),
              'accuracy': _lastKnownPosition!.accuracy,
            }
          : null,
      'consecutiveFailures': _consecutiveFailures,
      'hasTimer': _locationTimer != null,
    };
  }

  /// Reset failure counter and restart tracking if needed
  Future<void> resetAndRestart() async {
    print('🔄 Resetting location service and restarting...');

    _consecutiveFailures = 0;

    if (!_isTrackingLocation) {
      await startLocationTracking();
    } else {
      print('📍 Location tracking is already active');
    }
  }

  /// Check if location service is healthy
  bool get isHealthy {
    return _isTrackingLocation &&
        _consecutiveFailures < 3 &&
        _locationTimer != null;
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }

  /// Set custom update interval for location tracking
  void setUpdateInterval(Duration interval) {
    _updateInterval = interval;
    print('📅 Location update interval set to: ${interval.inSeconds}s');

    // If tracking is active, restart with new interval
    if (_isTrackingLocation) {
      stopLocationTracking();
      startLocationTracking();
    }
  }

  /// Get current update interval
  Duration get updateInterval => _updateInterval;
}
