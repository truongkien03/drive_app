import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/order.dart';

Future<void> initializeBackgroundProximityService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Không tự động start
      isForegroundMode: true,
      notificationChannelId: 'proximity_service',
      initialNotificationTitle: 'Đang kiểm tra vị trí giao hàng',
      initialNotificationContent: 'Dịch vụ kiểm tra khoảng cách đang chạy...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  List<Order>? _activeOrders;
  bool _hasLoadedOrders = false;
  Set<int> _arrivedOrderIds = {};

  Timer? timer;
  timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    // Lấy accessToken từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      print('BG Service: Không có token');
      timer.cancel();
      service.stopSelf();
      return;
    }
    // Nếu token là object JSON, lấy accessToken
    try {
      final dynamic tokenObj = jsonDecode(token);
      if (tokenObj is Map && tokenObj['accessToken'] != null) {
        token = tokenObj['accessToken'];
      }
    } catch (_) {}
    ApiService().setToken(token ?? '');

    // Lấy đơn hàng 1 lần duy nhất
    if (!_hasLoadedOrders) {
      print('📦 Chưa có dữ liệu đơn hàng, đang tải...');
      final api = ApiService();
      final response = await api.getDriverOrders();
      if (!response.success || response.data == null) {
        print('❌ Không thể tải đơn hàng, không thể bật kiểm tra tự động');
        timer.cancel();
        service.stopSelf();
        return;
      }
      _activeOrders = response.data;
      _hasLoadedOrders = true;
      _arrivedOrderIds.clear();
      print('✅ Đã tải ${_activeOrders!.length} đơn hàng thành công');
    }

    // Kiểm tra đã load đơn hàng chưa
    if (!_hasLoadedOrders || _activeOrders == null) {
      print('❌ Chưa có dữ liệu đơn hàng, vui lòng bấm nút để load trước');
      timer.cancel();
      service.stopSelf();
      return;
    }

    print('Bắt đầu kiểm tra khoảng cách...');
    print('📋 Tổng số đơn hàng: ${_activeOrders!.length}');
    for (final order in _activeOrders!) {
      print('   - Đơn hàng ${order.id}: status_code = ${order.statusCode}');
    }

    // Lọc đơn hàng có thể kiểm tra khoảng cách
    final activeDeliveryOrders = _activeOrders!.where((order) => order.statusCode == 1 || order.statusCode == 2).toList();
    if (activeDeliveryOrders.isEmpty) {
      print('📦 Không có đơn hàng nào đang trong quá trình giao');
      print('📦 Các đơn hàng hiện có:');
      for (final order in _activeOrders!) {
        print('   - Đơn hàng ${order.id}: status_code = ${order.statusCode}');
      }
      timer.cancel();
      service.stopSelf();
      print('⏹️ Đã dừng kiểm tra khoảng cách tự động (không còn đơn hàng)');
      return;
    }

    print('📦 Đang kiểm tra ${activeDeliveryOrders.length} đơn hàng đang giao');
    for (final order in activeDeliveryOrders) {
      print('🚚 Kiểm tra đơn hàng ${order.id} (trạng thái: ${order.statusCode})');
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print("vi trí hiện tại: ${currentPosition.latitude}, ${currentPosition.longitude}");
      } catch (e) {
        print('❌ Không thể lấy vị trí hiện tại: $e');
        continue;
      }
      print('📍 Vị trí hiện tại: ${currentPosition.latitude}, ${currentPosition.longitude}');
      double distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        order.toAddress.lat,
        order.toAddress.lon,
      );
      print('📏 Khoảng cách đến đơn hàng ${order.id}: ${distance.toStringAsFixed(2)}m');
      print('   Địa chỉ: ${order.toAddress.desc}');
      print('   Tọa độ: ${order.toAddress.lat}, ${order.toAddress.lon}');
      if (distance <= 50.0 && !_arrivedOrderIds.contains(order.id)) {
        _arrivedOrderIds.add(order.id);
        print('   ĐÃ TỚI! - Đơn hàng ${order.id}');
        print('   Khách hàng: ${order.customer.name} - ${order.customer.phone}');
        print('   Khoảng cách: ${distance.toStringAsFixed(2)}m');
        print('   Địa chỉ: ${order.toAddress.desc}');
        // Cập nhật trạng thái lên server
        final api = ApiService();
        await api.updateOrderArrived(order.id, note: 'Arrived by background service. Distance: ${distance.toStringAsFixed(1)}m');
        print('BG Service: Đã cập nhật trạng thái đơn ${order.id} thành đã tới!');
        // Sau khi cập nhật thành công đơn đầu tiên, dừng service
        timer.cancel();
        service.stopSelf();
        print('⏹️ Đã tới nơi và dừng kiểm tra.');
        return;
      }
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000;
  double dLat = _degreesToRadians(lat2 - lat1);
  double dLon = _degreesToRadians(lon2 - lon1);
  double a = 
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      (sin(dLon / 2) * sin(dLon / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
} 