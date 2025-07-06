import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage Firebase Realtime Database location tracking
class FirebaseLocationService {
  static Timer? _locationTimer;
  static Position? _lastKnownPosition;
  static DateTime? _lastUpdateTime;
  static bool _isTracking = false;
  static bool _isUpdating = false;
  static DatabaseReference? _database;
  static String? _driverId;
  static String? _driverPhoneNumber;
  static String? _driverName;

  // Configuration constants
  static const int _updateIntervalSeconds = 2; // 2-second intervals as specified
  static const double _minimumDistanceMeters = 5.0; // Lower threshold for frequent updates

  /// Initialize Firebase location service
  static Future<void> initialize() async {
    try {
      print('🔥 Initializing FirebaseLocationService...');

      // Initialize Firebase Database reference
      _database = FirebaseDatabase.instance.ref();

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

      // Load driver info from storage
      await _loadDriverInfo();

      print('✅ FirebaseLocationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing FirebaseLocationService: $e');
    }
  }

  /// Start Firebase location tracking with 2-second intervals
  static Future<void> startTracking() async {
    if (_isTracking) {
      print('⚠️ Firebase location tracking already started');
      return;
    }

    if (_database == null) {
      print('❌ Firebase database not initialized');
      return;
    }

    if (_driverId == null) {
      print('❌ Driver ID not available for Firebase tracking');
      return;
    }

    try {
      print('🟢 Starting Firebase location tracking with 2-second intervals...');
      _isTracking = true;

      // Get initial location and send immediately
      await _getCurrentLocationAndUpdate();

      // Start periodic updates every 2 seconds
      _locationTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (timer) async {
          if (_isTracking) {
            await _getCurrentLocationAndUpdate();
          } else {
            timer.cancel();
          }
        },
      );

      print('✅ Firebase location tracking started successfully');
    } catch (e) {
      print('❌ Error starting Firebase location tracking: $e');
      _isTracking = false;
    }
  }

  /// Stop Firebase location tracking
  static void stopTracking() {
    print('🔴 Stopping Firebase location tracking...');

    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    print('✅ Firebase location tracking stopped');
  }

  /// Get current location and update Firebase
  static Future<void> _getCurrentLocationAndUpdate() async {
    if (_isUpdating) {
      return; // Skip if already updating
    }

    try {
      _isUpdating = true;

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5), // Shorter timeout for frequent updates
      );

      // Update Firebase with current position
      await _updateLocationOnFirebase(position);
      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();

    } catch (e) {
      print('❌ Error getting current location for Firebase: $e');

      // If we can't get current location, try to use last known position
      if (_lastKnownPosition != null) {
        print('📍 Using last known position for Firebase update');
        await _updateLocationOnFirebase(_lastKnownPosition!);
      }
    } finally {
      _isUpdating = false;
    }
  }

  /// Update location on Firebase Realtime Database
  static Future<void> _updateLocationOnFirebase(Position position) async {
    if (_database == null || _driverId == null) {
      print('❌ Firebase database or driver ID not available');
      return;
    }

    try {
      // Prepare location data
      final locationData = {
        'userId': _driverId,
        'phoneNumber': _driverPhoneNumber ?? '',
        'name': _driverName ?? 'Driver',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().toIso8601String(),
        'isOnline': true,
        'status': 1, // Online status
      };

      // Update Firebase Realtime Database
      await _database!
          .child('drivers_location')
          .child(_driverId!)
          .set(locationData);

      print('📍 Firebase location updated: userId=$_driverId, lat=${position.latitude}, lng=${position.longitude}');

    } catch (e) {
      print('❌ Error updating location on Firebase: $e');
    }
  }

  /// Load driver information from storage
  static Future<void> _loadDriverInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get driver info from storage
      final driverData = prefs.getString('driver');
      if (driverData != null) {
        // Parse driver data if available
        // This would need to be adjusted based on how driver data is stored
        print('📱 Driver data loaded from storage');
      }

      // For now, we'll get basic info that should be available
      _driverPhoneNumber = prefs.getString('phone_number');

      // Driver ID might be stored separately or need to be extracted
      final driverIdString = prefs.getString('driver_id');
      if (driverIdString != null) {
        _driverId = driverIdString;
      }

      print('🔍 Driver info loaded: ID=$_driverId, Phone=$_driverPhoneNumber');
    } catch (e) {
      print('❌ Error loading driver info: $e');
    }
  }

  /// Set driver info manually (called from auth provider)
  static void setDriverInfo(String driverId, String? phoneNumber, String? name) {
    _driverId = driverId;
    _driverPhoneNumber = phoneNumber;
    _driverName = name;
    print('✅ Driver info set: ID=$driverId, Phone=$phoneNumber, Name=$name');
  }

  /// Manual location update
  static Future<void> updateLocationNow() async {
    if (!_isTracking) {
      print('⚠️ Firebase tracking not active, starting update anyway...');
    }

    print('📍 Manual Firebase location update requested...');
    await _getCurrentLocationAndUpdate();
  }

  /// Set driver status to offline in Firebase
  static Future<void> setDriverOffline() async {
    if (_database == null || _driverId == null) {
      print('❌ Cannot set driver offline: Firebase database or driver ID not available');
      return;
    }

    try {
      print('🔴 Setting driver offline in Firebase...');

      // Update driver status to offline but keep location data
      final offlineData = {
        'userId': _driverId,
        'phoneNumber': _driverPhoneNumber ?? '',
        'name': _driverName ?? 'Driver',
        'isOnline': false,
        'status': 2, // Offline status
        'lastUpdated': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _database!
          .child('drivers_location')
          .child(_driverId!)
          .update(offlineData);

      print('✅ Driver set to offline in Firebase');
    } catch (e) {
      print('❌ Error setting driver offline in Firebase: $e');
    }
  }

  /// Remove driver completely from Firebase (when logging out)
  static Future<void> removeDriverFromFirebase() async {
    if (_database == null || _driverId == null) return;

    try {
      await _database!
          .child('drivers_location')
          .child(_driverId!)
          .remove();

      print('🗑️ Driver location data removed from Firebase');
    } catch (e) {
      print('❌ Error removing driver from Firebase: $e');
    }
  }

  /// Check if currently tracking
  static bool get isTracking => _isTracking;

  /// Get last known position
  static Position? get lastKnownPosition => _lastKnownPosition;
}
