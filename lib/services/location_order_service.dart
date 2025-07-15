import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import 'api_service.dart';

/// Service dùng chung cho các màn hình: quản lý GPS, đơn hàng, proximity, gửi vị trí, cache...
class LocationOrderService {
  // Singleton pattern
  static final LocationOrderService _instance = LocationOrderService._internal();
  factory LocationOrderService() => _instance;
  LocationOrderService._internal();

  // State
  Position? currentPosition;
  List<LatLng> locationHistory = [];
  List<Order>? cachedOrders;
  DateTime? lastOrdersFetchTime;
  static const Duration ordersCacheDuration = Duration(minutes: 5);

  // Lấy vị trí hiện tại
  Future<Position?> getCurrentLocation({bool updateHistory = true}) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      currentPosition = position;
      print('Current location: ${position.latitude}, ${position.longitude}');
      if (updateHistory) {
        locationHistory.add(LatLng(position.latitude, position.longitude));
        print('Location history updated: ${locationHistory.length} points');
        if (locationHistory.length > 50) {
          locationHistory.removeAt(0);
        }
      }
      return position;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  // Gửi vị trí lên Firebase
  Future<void> sendLocationToFirebase(String driverId, Position position) async {
    try {
      Map<String, dynamic> locationData = {
        'accuracy': position.accuracy,
        'bearing': position.heading ?? 0.0,
        'isOnline': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed ?? 0.0,
        'status': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      await database.child('realtime-locations').child(driverId).set(locationData);
      print('✅ Location sent to Firebase for driver $driverId');
    } catch (e) {
      print('❌ Error sending location to Firebase: $e');
    }
  }

  // Lấy danh sách đơn hàng (có cache)
  Future<List<Order>?> getOrdersWithCache() async {
    try {
      final now = DateTime.now();
      if (cachedOrders != null &&
          lastOrdersFetchTime != null &&
          now.difference(lastOrdersFetchTime!) < ordersCacheDuration) {
        print('📦 Using cached orders (${cachedOrders!.length} orders)');
        return cachedOrders;
      }
      print('🔄 Fetching fresh orders from API...');
      final apiService = ApiService();
      final ordersResponse = await apiService.getDriverOrders();
      if (!ordersResponse.success || ordersResponse.data == null) {
        print('❌ Failed to fetch orders: ${ordersResponse.message}');
        return null;
      }
      cachedOrders = ordersResponse.data!;
      lastOrdersFetchTime = now;
      print('✅ Orders cached successfully (${cachedOrders!.length} orders)');
      return cachedOrders;
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return null;
    }
  }

  // Xóa cache đơn hàng
  void clearOrdersCache() {
    cachedOrders = null;
    lastOrdersFetchTime = null;
    print('🗑️ Orders cache cleared');
  }

  // Tính khoảng cách giữa 2 điểm GPS (Haversine formula)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
} 