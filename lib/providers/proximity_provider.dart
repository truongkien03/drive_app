import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/order.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ProximityProvider extends ChangeNotifier {
  // State variables
  bool _isAutoProximityChecking = false;
  Timer? _proximityCheckTimer;
  List<Order>? _activeOrders;
  bool _hasLoadedOrders = false;
  Set<int> _arrivedOrders = {};
  Position? _currentPosition;
  final ApiService _apiService = ApiService();
  List<LatLng> _locationHistory = [];
  String? _lastUpdateTime;

  // Getters
  bool get isAutoProximityChecking => _isAutoProximityChecking;
  List<Order>? get activeOrders => _activeOrders;
  bool get hasLoadedOrders => _hasLoadedOrders;
  Position? get currentPosition => _currentPosition;
  List<LatLng> get locationHistory => _locationHistory;
  String? get lastUpdateTime => _lastUpdateTime;

  @override
  void dispose() {
    _proximityCheckTimer?.cancel();
    super.dispose();
  }

  /// Hàm bật/tắt kiểm tra khoảng cách tự động
  Future<void> toggleAutoProximityChecking(BuildContext context) async {
    if (_isAutoProximityChecking) {
      // Tắt chế độ tự động
      _proximityCheckTimer?.cancel();
      _proximityCheckTimer = null;
      _isAutoProximityChecking = false;
      print('Đã dừng kiểm tra khoảng cách tự động');
      notifyListeners();
      return;
    }
    // Kiểm tra xem đã load đơn hàng chưa
    if (!_hasLoadedOrders) {
      print('Chưa có dữ liệu đơn hàng, đang tải...');
      await _loadOrdersOnce();
      if (!_hasLoadedOrders) {
        print('Không thể tải đơn hàng, không thể bật kiểm tra tự động');
        return;
      }
    }
    // Bật chế độ tự động
    _isAutoProximityChecking = true;
    print("Bắt đầu kiểm tra khoảng cách tự động");
    await _checkProximityToDestination();
    _proximityCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (_isAutoProximityChecking) {
        print("Đang tính khoảng cách...");
        await _checkProximityToDestination();
      } else {
        timer.cancel();
      }
    });
    print('Đã bật kiểm tra khoảng cách tự động (mỗi 2 giây)');
    notifyListeners();
  }

  /// Load đơn hàng từ API một lần duy nhất
  Future<void> _loadOrdersOnce() async {
    try {
      print('Đang tải dữ liệu đơn hàng từ API...');
      final ordersResponse = await _apiService.getDriverOrders();
      if (!ordersResponse.success || ordersResponse.data == null) {
        print('Không thể tải đơn hàng: ${ordersResponse.message}');
        return;
      }
      _activeOrders = ordersResponse.data!;
      _hasLoadedOrders = true;
      _arrivedOrders.clear();
      print('Đã tải thành công ${_activeOrders!.length} đơn hàng');
    } catch (e) {
      print('Lỗi khi tải đơn hàng: $e');
    }
  }

  /// Lấy vị trí hiện tại, lưu vào history, cập nhật _lastUpdateTime
  Future<void> getCurrentLocationWithHistory() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      _currentPosition = position;
      _lastUpdateTime = DateTime.now().toString().substring(11, 19);
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      _locationHistory.add(newPoint);
      if (_locationHistory.length > 50) {
        _locationHistory.removeAt(0);
      }
      print('GPS Updated (with history): [32m${position.latitude}, ${position.longitude}[0m');
      notifyListeners();
    } catch (e) {
      print('Error getting current location (with history): $e');
    }
  }

  /// Kiểm tra khoảng cách đến địa chỉ giao hàng
  Future<void> _checkProximityToDestination() async {
    try {
      print('Bắt đầu kiểm tra khoảng cách...');
      if (!_hasLoadedOrders || _activeOrders == null) {
        print('Chưa có dữ liệu đơn hàng, vui lòng bấm nút để load trước');
        return;
      }
      if (_currentPosition == null) {
        await getCurrentLocationWithHistory();
      }
      if (_currentPosition == null) {
        print('Không thể lấy vị trí hiện tại');
        return;
      }
      print('Vị trí hiện tại: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      print('Tổng số đơn hàng: ${_activeOrders!.length}');
      for (final order in _activeOrders!) {
        print('  - Đơn hàng ${order.id}: status_code = ${order.statusCode}');
      }
      final activeDeliveryOrders = _activeOrders!.where((order) => _canCheckProximity(order.statusCode)).toList();
      if (activeDeliveryOrders.isEmpty) {
        print('Không có đơn hàng nào đang trong quá trình giao');
        print('Các đơn hàng hiện có:');
        for (final order in _activeOrders!) {
          final statusText = _getStatusText(order.statusCode);
          print('   - Đơn hàng ${order.id}: status_code = ${order.statusCode} ($statusText)');
        }
        return;
      }
      print('Đang kiểm tra ${activeDeliveryOrders.length} đơn hàng đang giao');
      for (final order in activeDeliveryOrders) {
        print('Kiểm tra đơn hàng ${order.id} (trạng thái: ${order.statusCode})');

        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          order.toAddress.lat,
          order.toAddress.lon,
        );
        print('Khoảng cách đến đơn hàng ${order.id}: ${distance.toStringAsFixed(2)}m');
        print('Địa chỉ: ${order.toAddress.desc}');
        print('Tọa độ: ${order.toAddress.lat}, ${order.toAddress.lon}');
        if (distance <= 15.0 && !_arrivedOrders.contains(order.id)) {
          print('ĐÃ TỚI! - Đơn hàng ${order.id}');
          print('Khách hàng: ${order.customer.name} - ${order.customer.phone}');
          print('Khoảng cách: ${distance.toStringAsFixed(2)}m');
          print('Địa chỉ: ${order.toAddress.desc}');
          _arrivedOrders.add(order.id);
          await _updateOrderArrivedStatus(order.id, distance);
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra khoảng cách: $e');
    }
  }

  /// Cập nhật trạng thái đơn hàng thành "đã tới" lên server
  Future<void> _updateOrderArrivedStatus(int orderId, double distance) async {
    try {
      print('Đang cập nhật trạng thái đơn hàng $orderId thành "đã tới"...');
      final note = 'Driver arrived at delivery location. Distance: ${distance.toStringAsFixed(1)}m';
      final response = await _apiService.updateOrderArrived(orderId, note: note);
      if (response.success && response.data != null) {
        print('Đã cập nhật trạng thái đơn hàng $orderId thành công');
        _updateLocalOrderStatus(orderId, response.data!);
      } else {
        print('Lỗi cập nhật trạng thái đơn hàng: ${response.message}');
        _arrivedOrders.remove(orderId);
      }
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái đơn hàng: $e');
      _arrivedOrders.remove(orderId);
    }
  }

  /// Cập nhật trạng thái đơn hàng trong danh sách local
  void _updateLocalOrderStatus(int orderId, Order updatedOrder) {
    if (_activeOrders != null) {
      final index = _activeOrders!.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _activeOrders![index] = updatedOrder;
        print('Đã cập nhật trạng thái đơn hàng $orderId trong danh sách local');
        notifyListeners();
      }
    }
  }

  /// Kiểm tra xem đơn hàng có thể kiểm tra khoảng cách không
  bool _canCheckProximity(int statusCode) {
    return statusCode == 1 || statusCode == 2;
  }

  /// Chuyển đổi status code thành text
  String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 0:
        return 'Chờ xác nhận';
      case 1:
        return 'Đã nhận đơn';
      case 2:
        return 'Đang giao';
      case 3:
        return 'Đã giao xong';
      case 4:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  /// Hàm tính khoảng cách giữa 2 điểm GPS (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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