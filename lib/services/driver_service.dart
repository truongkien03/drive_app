import 'package:flutter/material.dart';
import 'api_service.dart';
import 'driver_fcm_service.dart';
import 'location_service.dart';
import 'navigation_service.dart';

/// Service to manage all driver-related operations and services
class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal();

  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  bool _isDriverOnline = false;
  String? _driverToken;

  /// Initialize all driver services
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing Driver Services...');

      // Initialize FCM service
      await DriverFCMService.initialize();

      print('✅ Driver Services initialized successfully');
    } catch (e) {
      print('❌ Error initializing Driver Services: $e');
    }
  }

  /// Set driver authentication token
  void setDriverToken(String token) {
    _driverToken = token;
    _apiService.setToken(token);
    print('🔑 Driver token set in DriverService');
  }

  /// Handle driver going online
  Future<void> goOnline() async {
    try {
      print('🟢 Driver going online...');

      if (_driverToken == null) {
        print('❌ No driver token available');
        return;
      }

      // 1. Set driver status to online via API
      final response = await _apiService.setDriverOnline();
      if (!response.success) {
        print('❌ Failed to set driver online: ${response.message}');
        return;
      }

      // 2. Refresh FCM token
      await DriverFCMService.refreshFCMToken();

      // 3. Start location tracking
      await _startLocationServices();

      _isDriverOnline = true;
      print('✅ Driver is now ONLINE');
    } catch (e) {
      print('❌ Error going online: $e');
    }
  }

  /// Handle driver going offline
  Future<void> goOffline() async {
    try {
      print('🔴 Driver going offline...');

      // 1. Stop location tracking
      _stopLocationServices();

      // 2. Set driver status to offline via API
      if (_driverToken != null) {
        final response = await _apiService.setDriverOffline();
        if (!response.success) {
          print('❌ Failed to set driver offline: ${response.message}');
        }
      }

      // 3. Remove FCM token
      await DriverFCMService.removeToken();

      _isDriverOnline = false;
      print('✅ Driver is now OFFLINE');
    } catch (e) {
      print('❌ Error going offline: $e');
    }
  }

  /// Start location-related services
  Future<void> _startLocationServices() async {
    try {
      print('📍 Starting location services...');

      // Check location permission first
      final hasPermission = await _locationService.checkLocationPermission();
      if (!hasPermission) {
        print('❌ No location permission - cannot start tracking');
        return;
      }

      // Start location tracking
      await _locationService.startLocationTracking();
      print('✅ Location services started');
    } catch (e) {
      print('❌ Error starting location services: $e');
    }
  }

  /// Stop location-related services
  void _stopLocationServices() {
    try {
      print('🛑 Stopping location services...');
      _locationService.stopLocationTracking();
      print('✅ Location services stopped');
    } catch (e) {
      print('❌ Error stopping location services: $e');
    }
  }

  /// Update location immediately
  Future<void> updateLocationNow() async {
    try {
      if (!_isDriverOnline) {
        print('⚠️ Driver is offline - skipping location update');
        return;
      }

      await _locationService.forceUpdateLocation();
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }

  /// Handle driver logout
  Future<void> logout() async {
    try {
      print('👋 Driver logging out...');

      // Go offline first
      await goOffline();

      // Clear token
      _driverToken = null;
      _apiService.setToken('');

      print('✅ Driver logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  /// Check if driver is online
  bool get isOnline => _isDriverOnline;

  /// Get location service health status
  Map<String, dynamic> getLocationHealth() {
    return _locationService.getLocationStats();
  }

  /// Check if location service is healthy
  bool get isLocationHealthy => _locationService.isHealthy;

  /// Reset location service on failures
  Future<void> resetLocationService() async {
    try {
      print('🔄 Resetting location service...');
      await _locationService.resetAndRestart();
      _showError('Location service reset successfully');
    } catch (e) {
      print('❌ Error resetting location service: $e');
      _showError('Failed to reset location service: $e');
    }
  }

  /// Monitor location service health
  Future<void> monitorLocationHealth() async {
    if (!_isDriverOnline) return;

    final stats = getLocationHealth();
    final consecutiveFailures = stats['consecutiveFailures'] as int;

    if (consecutiveFailures >= 3) {
      print(
          '⚠️ Location service unhealthy - consecutive failures: $consecutiveFailures');
      _showError('Location update issues detected. Tap to reset.');

      // Auto-reset if too many failures
      if (consecutiveFailures >= 5) {
        await resetLocationService();
      }
    }
  }

  /// Show error message to user
  void _showError(String message) {
    final context = NavigationService.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle emergency situations (e.g., lost connection)
  Future<void> handleEmergency() async {
    try {
      print('🚨 Handling emergency situation...');

      // Try to update location with high accuracy
      final position = await _locationService.getHighAccuracyLocation();
      if (position != null) {
        print(
            '🎯 Emergency location: ${position.latitude}, ${position.longitude}');
      }

      // Refresh FCM token
      await DriverFCMService.refreshFCMToken();

      // Reset location service if unhealthy
      if (!isLocationHealthy) {
        await resetLocationService();
      }
    } catch (e) {
      print('❌ Error handling emergency: $e');
    }
  }

  /// Dispose all services
  void dispose() {
    _stopLocationServices();
  }
}
