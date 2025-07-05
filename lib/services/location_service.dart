import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

class LocationService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String _baseUrl = 'http://localhost:8000/api'; // Thay đổi cho production

  // Sử dụng Firebase project hiện tại thay vì hardcode URL
  // Firebase sẽ tự động sử dụng URL từ google-services.json

  // Khởi tạo Firebase
  static Future<void> initialize() async {
    // Không cần khởi tạo Firebase ở đây vì đã khởi tạo trong main.dart
    print('🔥 LocationService initialized with Firebase project: appecommerce-d6bc7');
  }

  // Yêu cầu quyền location
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  // Lấy vị trí hiện tại
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Cập nhật vị trí lên Firebase
  static Future<void> updateLocationToFirebase({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? bearing,
    double? speed,
    bool? isOnline,
    int? status,
  }) async {
    try {
      // Tạo dữ liệu location
      Map<String, dynamic> locationData = {
        'accuracy': accuracy ?? 5.0,
        'bearing': bearing ?? 0.0,
        'isOnline': isOnline ?? true,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed ?? 0.0,
        'status': status ?? 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Cập nhật lên Firebase Realtime Database
      await _database
          .child('realtime-locations')
          .child(driverId)
          .set(locationData);

      print('🔥 Location updated to Firebase: $driverId');

      // Gửi đồng thời đến Laravel API
      await _sendToLaravelAPI(driverId, locationData);

    } catch (e) {
      print('❌ Error updating location to Firebase: $e');
    }
  }

  // Gửi dữ liệu đến Laravel API
  static Future<void> _sendToLaravelAPI(String driverId, Map<String, dynamic> locationData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tracker/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': driverId,
          'latitude': locationData['latitude'],
          'longitude': locationData['longitude'],
          'accuracy': locationData['accuracy'],
          'bearing': locationData['bearing'],
          'speed': locationData['speed'],
          'is_online': locationData['isOnline'],
          'status': locationData['status'],
          'timestamp': locationData['timestamp'],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Location sent to Laravel API successfully');
      } else {
        print('❌ Error sending to Laravel API: ${response.body}');
      }
    } catch (e) {
      print('💥 Exception sending to Laravel API: $e');
    }
  }

  // Lấy vị trí từ Firebase
  static Stream<DatabaseEvent> getLocationStream(String driverId) {
    return _database
        .child('realtime-locations')
        .child(driverId)
        .onValue;
  }

  // Lấy tất cả vị trí từ Firebase
  static Stream<DatabaseEvent> getAllLocationsStream() {
    return _database
        .child('realtime-locations')
        .onValue;
  }

  // Cập nhật trạng thái online/offline
  static Future<void> updateOnlineStatus(String driverId, bool isOnline) async {
    try {
      await _database
          .child('realtime-locations')
          .child(driverId)
          .child('isOnline')
          .set(isOnline);

      print('✅ Online status updated: $driverId - $isOnline');
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }
}
