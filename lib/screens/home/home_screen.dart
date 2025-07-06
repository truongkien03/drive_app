import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../services/driver_location_service.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../auth/phone_input_screen.dart';
import 'orders_screen.dart';
import 'trip_sharing_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';
import 'profile_detail_screen.dart';
import 'real_time_map_screen.dart';
import '../../test/gps_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  List<LatLng> _locationHistory = [];
  String _locationStatus = 'Đang khởi tạo GPS...';
  String _lastUpdateTime = '';
  bool _isMapReady = false;
  int _totalUpdates = 0;
  int _successfulUpdates = 0;

  // Cached orders data
  List<Order>? _cachedOrders;
  DateTime? _lastOrdersFetchTime;
  static const Duration _ordersCacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Auto proximity checking
  Timer? _proximityCheckTimer;
  bool _isAutoProximityChecking = false;
  
  // Global orders data for proximity checking
  List<Order>? _activeOrders;
  bool _hasLoadedOrders = false;
  
  // Track orders that have been marked as arrived
  Set<int> _arrivedOrders = {};

  // Default location (Hanoi)
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartTracking();
    });
  }

  void _checkAndStartTracking() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isOnline) {
      _initializeLocationTracking();
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _proximityCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isOnline) {
      setState(() {
        _locationStatus = 'Tài xế offline - chưa bật GPS tracking';
      });
      return;
    }

    try {
      setState(() {
        _locationStatus = 'Đang kiểm tra quyền GPS...';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'GPS chưa được bật trên thiết bị';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Quyền GPS bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Quyền GPS bị từ chối vĩnh viễn';
        });
        return;
      }

      await _getCurrentLocation();
      _startLocationTracking();

      setState(() {
        _locationStatus = 'GPS đang hoạt động';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Lỗi khởi tạo GPS: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _lastUpdateTime = DateTime.now().toString().substring(11, 19);
      });

      LatLng newPoint = LatLng(position.latitude, position.longitude);
      _locationHistory.add(newPoint);

      if (_locationHistory.length > 50) {
        _locationHistory.removeAt(0);
      }

      if (!_isMapReady) {
        _mapController.move(newPoint, 16.0);
        setState(() {
          _isMapReady = true;
        });
      }

      print('📍 GPS Updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error getting current location: $e');
    }
  }

  /// Hàm gửi tọa độ lên Firebase từ _getCurrentLocation
  Future<void> _sendLocationToFirebaseFromGetLocation(Position position) async {
    try {
      // Lấy driverId từ authProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverId = authProvider.driver?.id?.toString() ?? 'unknown';

      // Tạo dữ liệu location theo cấu trúc Firebase yêu cầu
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

      // Sử dụng Firebase Database instance mặc định
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      print("📍 Sending location to Firebase: $locationData");
      // Gửi lên Firebase theo đường dẫn: realtime-locations/{driverId}
      await database
          .child('realtime-locations')
          .child(driverId)
          .set(locationData);

      print('📍 Location auto-sent to Firebase from _getCurrentLocation: userId=$driverId, lat=${position.latitude}, lng=${position.longitude}');
    } catch (e) {
      print('❌ Error auto-sending location to Firebase from _getCurrentLocation: $e');
    }
  }

  void _startLocationTracking() {
    // Thay đổi interval thành 5 giây và gửi lên Firebase
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isOnline) {
        await _getCurrentLocation();
        await _sendLocationToFirebase(); // Gửi lên Firebase mỗi 5s
         // Kiểm tra khoảng cách đến địa điểm giao hàng
      } else {
        setState(() {
          _locationStatus = 'Tài xế offline - dừng tracking';
        });
        timer.cancel();
      }
    });
  }

  Future<void> _sendLocationToServer() async {
    if (_currentPosition == null) return;

    try {
      _totalUpdates++;
      await DriverLocationService.updateLocationNow();
      // await _addLocationToFirebase()
      setState(() {
        _successfulUpdates++;
      });
      print('✅ Location sent to server successfully');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
  }

  /// Hàm gửi tọa độ lên Firebase theo cấu trúc yêu cầu
  Future<void> _sendLocationToFirebase() async {
    try {
      print("🚀 Starting _sendLocationToFirebase function");

      // Lấy vị trí hiện tại
      Position? position;

      if (_currentPosition == null) {
        // Nếu chưa có vị trí, lấy vị trí hiện tại
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          );
          setState(() {
            _currentPosition = position;
          });
        } catch (e) {
          print("❌ Error getting current position: $e");
          return;
        }
      } else {
        position = _currentPosition;
      }

      // Lấy driverId từ authProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverId = authProvider.driver?.id?.toString() ?? 'unknown';
      print("🔑 Driver ID: $driverId");

      // Tạo dữ liệu location theo cấu trúc Firebase yêu cầu
      Map<String, dynamic> locationData = {
        'accuracy': position!.accuracy,
        'bearing': position.heading ?? 0.0,
        'isOnline': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed ?? 0.0,
        'status': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      print("📍 Location data prepared: $locationData");

      // Sử dụng Firebase Database instance mặc định
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      print("🔥 Firebase database instance created: ${database.toString()}");

      print("⏳ About to send to Firebase...");

      // Gửi lên Firebase theo đường dẫn: realtime-locations/{driverId}
      try {
        await database
            .child('realtime-locations')
            .child(driverId)
            .set(locationData)
            .timeout(Duration(seconds: 15)); // Add timeout

        print("✅ Firebase set operation completed successfully!");
        print("🎯 Gửi tọa độ lên firebase thành công: ${database.toString()}");

      } catch (firebaseError) {
        print("💥 Firebase set operation failed: $firebaseError");
        print("🔍 Error type: ${firebaseError.runtimeType}");
        throw firebaseError; // Re-throw to be caught by outer catch
      }

      // Cập nhật UI
      setState(() {
        _lastUpdateTime = DateTime.now().toString().substring(11, 19);
        _successfulUpdates++;
        _totalUpdates++;
      });

      print('✅ Location sent to Firebase successfully:');
      print('   URL: https://delivery-0805-default-rtdb.firebaseio.com/realtime-locations/$driverId');
      print('   Data: $locationData');

    } catch (e) {
      // Hiển thị lỗi chi tiết
      print('💥 DETAILED ERROR in _sendLocationToFirebase: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Error toString: ${e.toString()}');

      // Hiển thị lỗi trên UI nếu cần
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi gửi tọa độ lên Firebase: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Kiểm tra xem đơn hàng có đang trong quá trình giao không
  bool _isOrderInDelivery(int statusCode) {
    // Status code meanings:
    // 0: Chờ xác nhận
    // 1: Đã nhận đơn, đang giao
    // 2: Đang giao hàng
    // 3: Đã giao xong
    // 4: Đã hủy
    return statusCode == 1 || statusCode == 2;
  }

  /// Kiểm tra xem đơn hàng có thể kiểm tra khoảng cách không
  bool _canCheckProximity(int statusCode) {
    // Chỉ kiểm tra đơn hàng đang giao (status 1, 2) và chưa hoàn thành (status 3)
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

  /// Cập nhật trạng thái đơn hàng thành "đã tới" lên server
  Future<void> _updateOrderArrivedStatus(int orderId, double distance) async {
    try {
      print('🔄 Đang cập nhật trạng thái đơn hàng $orderId thành "đã tới"...');
      
      final apiService = ApiService();
      final note = 'Driver arrived at delivery location. Distance: ${distance.toStringAsFixed(1)}m';
      
      final response = await apiService.updateOrderArrived(orderId, note: note);

      if (response.success && response.data != null) {
        print('✅ Đã cập nhật trạng thái đơn hàng $orderId thành công');
        
        // Cập nhật đơn hàng trong danh sách local
        _updateLocalOrderStatus(orderId, response.data!);
        
        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã cập nhật trạng thái đơn hàng #$orderId'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Lỗi cập nhật trạng thái đơn hàng: ${response.message}');
        
        // Xóa khỏi danh sách đã xử lý để có thể thử lại
        _arrivedOrders.remove(orderId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi cập nhật trạng thái: ${response.message}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Lỗi khi cập nhật trạng thái đơn hàng: $e');
      
      // Xóa khỏi danh sách đã xử lý để có thể thử lại
      _arrivedOrders.remove(orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💥 Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Cập nhật trạng thái đơn hàng trong danh sách local
  void _updateLocalOrderStatus(int orderId, Order updatedOrder) {
    if (_activeOrders != null) {
      final index = _activeOrders!.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _activeOrders![index] = updatedOrder;
        print('📝 Đã cập nhật trạng thái đơn hàng $orderId trong danh sách local');
        
        // Kiểm tra xem còn đơn hàng nào cần theo dõi không
        _checkIfShouldStopProximityChecking();
      }
    }
  }

  /// Kiểm tra xem có nên dừng kiểm tra khoảng cách không
  void _checkIfShouldStopProximityChecking() {
    if (_activeOrders == null) return;
    
    final remainingOrders = _activeOrders!.where((order) => 
      _canCheckProximity(order.statusCode)
    ).toList();
    
    if (remainingOrders.isEmpty && _isAutoProximityChecking) {
      print('📦 Không còn đơn hàng nào cần theo dõi, dừng kiểm tra khoảng cách');
      
      // Dừng timer
      _proximityCheckTimer?.cancel();
      _proximityCheckTimer = null;
      _isAutoProximityChecking = false;
      
      // Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã hoàn thành tất cả đơn hàng!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Cập nhật UI
        setState(() {});
      }
    }
  }

  /// Hàm kiểm tra khoảng cách đến địa chỉ giao hàng (sử dụng dữ liệu đã load)
  Future<void> _checkProximityToDestination() async {
    try {
      print('🎯 Bắt đầu kiểm tra khoảng cách...');

      // Kiểm tra xem đã load đơn hàng chưa
      if (!_hasLoadedOrders || _activeOrders == null) {
        print('❌ Chưa có dữ liệu đơn hàng, vui lòng bấm nút để load trước');
        return;
      }

      // Lấy vị trí hiện tại
      if (_currentPosition == null) {
        await _getCurrentLocation();
      }

      if (_currentPosition == null) {
        print('❌ Không thể lấy vị trí hiện tại');
        return;
      }

      print('📍 Vị trí hiện tại: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Debug: In ra tất cả đơn hàng và status code
      print('📋 Tổng số đơn hàng: ${_activeOrders!.length}');
      for (final order in _activeOrders!) {
        print('   - Đơn hàng ${order.id}: status_code = ${order.statusCode}');
      }

      // Lọc đơn hàng có thể kiểm tra khoảng cách
      final activeDeliveryOrders = _activeOrders!.where((order) => 
        _canCheckProximity(order.statusCode)
      ).toList();

      if (activeDeliveryOrders.isEmpty) {
        print('📦 Không có đơn hàng nào đang trong quá trình giao');
        print('📦 Các đơn hàng hiện có:');
        for (final order in _activeOrders!) {
          final statusText = _getStatusText(order.statusCode);
          print('   - Đơn hàng ${order.id}: status_code = ${order.statusCode} ($statusText)');
        }
        return;
      }

      print('📦 Đang kiểm tra ${activeDeliveryOrders.length} đơn hàng đang giao');

      // Kiểm tra từng đơn hàng
      for (final order in activeDeliveryOrders) {
        print('🚚 Kiểm tra đơn hàng ${order.id} (trạng thái: ${order.statusCode})');

        // Tính khoảng cách từ vị trí hiện tại đến địa chỉ giao hàng
        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          order.toAddress.lat,
          order.toAddress.lon,
        );

        print('📏 Khoảng cách đến đơn hàng ${order.id}: ${distance.toStringAsFixed(2)}m');
        print('   Địa chỉ: ${order.toAddress.desc}');
        print('   Tọa độ: ${order.toAddress.lat}, ${order.toAddress.lon}');

        // Nếu khoảng cách <= 10m và chưa được đánh dấu là đã tới
        if (distance <= 10.0 && !_arrivedOrders.contains(order.id)) {
          print('🎉 ĐÃ TỚI! - Đơn hàng ${order.id}');
          print('   Khách hàng: ${order.customer.name} - ${order.customer.phone}');
          print('   Khoảng cách: ${distance.toStringAsFixed(2)}m');
          print('   Địa chỉ: ${order.toAddress.desc}');

          // Đánh dấu đơn hàng này đã được xử lý
          _arrivedOrders.add(order.id);

          // Cập nhật trạng thái lên server
          await _updateOrderArrivedStatus(order.id, distance);

          // Hiển thị thông báo trên UI
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ĐÃ TỚI địa chỉ giao hàng!\nKhoảng cách: ${distance.toStringAsFixed(1)}m\nKhách hàng: ${order.customer.name}'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Chi tiết',
                  textColor: Colors.white,
                  onPressed: () {
                    // Có thể mở màn hình chi tiết đơn hàng
                  },
                ),
              ),
            );
          }
        }
      }

    } catch (e) {
      print('❌ Lỗi khi kiểm tra khoảng cách: $e');
    }
  }

  /// Load đơn hàng từ API một lần duy nhất
  Future<void> _loadOrdersOnce() async {
    try {
      print('🔄 Đang tải dữ liệu đơn hàng từ API...');
      
      final apiService = ApiService();
      final ordersResponse = await apiService.getDriverOrders();

      if (!ordersResponse.success || ordersResponse.data == null) {
        print('❌ Không thể tải đơn hàng: ${ordersResponse.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi tải đơn hàng: ${ordersResponse.message}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Lưu vào biến toàn cục
      _activeOrders = ordersResponse.data!;
      _hasLoadedOrders = true;
      
      // Reset danh sách đơn hàng đã xử lý khi load dữ liệu mới
      _arrivedOrders.clear();

      print('✅ Đã tải thành công ${_activeOrders!.length} đơn hàng');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tải ${_activeOrders!.length} đơn hàng thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      print('❌ Lỗi khi tải đơn hàng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Bật/tắt chế độ kiểm tra khoảng cách tự động
  void _toggleAutoProximityChecking() async {
    if (_isAutoProximityChecking) {
      // Tắt chế độ tự động
      _proximityCheckTimer?.cancel();
      _proximityCheckTimer = null;
      _isAutoProximityChecking = false;
      
      print('⏹️ Đã dừng kiểm tra khoảng cách tự động');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏹️ Đã dừng kiểm tra khoảng cách tự động'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Kiểm tra xem đã load đơn hàng chưa
      if (!_hasLoadedOrders) {
        print('📦 Chưa có dữ liệu đơn hàng, đang tải...');
        
        // Hiển thị thông báo đang tải
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📦 Đang tải dữ liệu đơn hàng...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        // Load đơn hàng trước
        await _loadOrdersOnce();
        
        // Kiểm tra lại sau khi load
        if (!_hasLoadedOrders) {
          print('❌ Không thể tải đơn hàng, không thể bật kiểm tra tự động');
          return;
        }
      }
      
      // Bật chế độ tự động
      _isAutoProximityChecking = true;
      print("🎯 Bắt đầu kiểm tra khoảng cách tự động");
      
      // Chạy kiểm tra ngay lập tức
      _checkProximityToDestination();
      
      // Thiết lập timer chạy mỗi 2 giây
      _proximityCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (_isAutoProximityChecking) {
          print("📏 Đang tính khoảng cách...");
          _checkProximityToDestination();
        } else {
          timer.cancel();
        }
      });
      
      print('▶️ Đã bật kiểm tra khoảng cách tự động (mỗi 2 giây)');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('▶️ Đã bật kiểm tra khoảng cách tự động (mỗi 2 giây)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Cập nhật UI
    setState(() {});
  }

  /// Hàm tính khoảng cách giữa 2 điểm GPS (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Bán kính Trái Đất tính bằng mét

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Khoảng cách tính bằng mét
  }

  /// Chuyển đổi độ sang radian
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Hàm lấy danh sách đơn hàng với cache
  Future<List<Order>?> _getOrdersWithCache() async {
    try {
      final now = DateTime.now();

      // Kiểm tra xem cache còn hiệu lực không
      if (_cachedOrders != null &&
          _lastOrdersFetchTime != null &&
          now.difference(_lastOrdersFetchTime!) < _ordersCacheDuration) {
        print('📦 Using cached orders (${_cachedOrders!.length} orders)');
        return _cachedOrders;
      }

      // Cache hết hạn hoặc chưa có cache, gọi API
      print('🔄 Fetching fresh orders from API...');
      final apiService = ApiService();
      final ordersResponse = await apiService.getDriverOrders();

      if (!ordersResponse.success || ordersResponse.data == null) {
        print('❌ Failed to fetch orders: ${ordersResponse.message}');
        return null;
      }

      // Lưu vào cache
      _cachedOrders = ordersResponse.data!;
      _lastOrdersFetchTime = now;

      print('✅ Orders cached successfully (${_cachedOrders!.length} orders)');
      return _cachedOrders;

    } catch (e) {
      print('❌ Error fetching orders: $e');
      return null;
    }
  }

  /// Hàm xóa cache đơn hàng (gọi khi cần refresh)
  void _clearOrdersCache() {
    _cachedOrders = null;
    _lastOrdersFetchTime = null;
    print('🗑️ Orders cache cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (authProvider.driver == null && !authProvider.isLoading) {
            // If driver is null and not loading, it means user logged out or auth failed
            // Use a post frame callback to avoid calling Navigator during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhoneInputScreen(isLogin: true),
                  ),
                  (route) => false,
                );
              }
            });

            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang chuyển hướng...'),
                  ],
                ),
              ),
            );
          }

          // Main content - GPS Tracking Map
          return Stack(
            children: [
              // Map with GPS tracking
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)
                      : _defaultLocation,
                  zoom: 16.0,
                  maxZoom: 19.0,
                  minZoom: 10.0,
                ),
                children: [
                  // Map tiles
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.drive_app',
                  ),

                  // Location history trail
                  if (_locationHistory.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _locationHistory,
                          strokeWidth: 3.0,
                          color: Colors.blue.withOpacity(0.6),
                        ),
                      ],
                    ),

                  // Current location marker
                  MarkerLayer(
                    markers: [
                      // Current driver position
                      if (_currentPosition != null)
                        Marker(
                          point: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 20,
                            ),
                            width: 30,
                            height: 30,
                          ),
                        ),

                      // Sample delivery locations
                      Marker(
                        point: LatLng(21.0245, 105.8412),
                        child: Container(
                          child: Icon(
                            Icons.local_shipping,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                      ),
                      Marker(
                        point: LatLng(21.0325, 105.8482),
                        child: Container(
                          child: Icon(
                            Icons.delivery_dining,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // GPS Status Panel (top)
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: authProvider.isOnline
                            ? Colors.green[50]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: authProvider.isOnline
                              ? Colors.green
                              : Colors.grey,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            authProvider.isOnline
                                ? Icons.gps_fixed
                                : Icons.gps_off,
                            color: authProvider.isOnline
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authProvider.isOnline
                                      ? 'ONLINE - GPS TRACKING'
                                      : 'OFFLINE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: authProvider.isOnline
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (authProvider.isOnline &&
                                    _currentPosition != null)
                                  Text(
                                    '📍 ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600]),
                                  )
                                else if (authProvider.isOnline)
                                  Text(
                                    _locationStatus,
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          if (authProvider.isOnline && _currentPosition != null)
                            IconButton(
                              onPressed: () {
                                _mapController.move(
                                    LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    16.0);
                              },
                              icon: Icon(Icons.my_location,
                                  size: 20, color: Colors.blue),
                              constraints:
                                  BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Menu button overlay
              Positioned(
                top: 120,
                left: 16,
                child: Builder(
                  builder: (context) => FloatingActionButton(
                    heroTag: "menu",
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Icon(Icons.menu),
                  ),
                ),
              ),

              // Status card overlay - Thu nhỏ và di chuyển xuống thấp hơn
              Positioned(
                bottom: 140,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: authProvider.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.statusText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: authProvider.isOnline,
                          onChanged: authProvider.isLoading
                              ? null
                              : (value) async {
                                  if (value) {
                                    bool success =
                                        await authProvider.setDriverOnline();
                                    if (success) {
                                      _initializeLocationTracking();
                                    } else if (authProvider.error != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Lỗi: ${authProvider.error}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    await authProvider.setDriverOffline();
                                    _locationUpdateTimer?.cancel();
                                    setState(() {
                                      _locationStatus = 'Đã dừng GPS tracking';
                                      _currentPosition = null;
                                      _locationHistory.clear();
                                    });
                                  }
                                },
                          activeColor: Colors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick action buttons
              Positioned(
                bottom: 20,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "location",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      onPressed: _currentPosition != null
                          ? () {
                              _mapController.move(
                                  LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  16.0);
                            }
                          : null,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),

                    // Nút gửi tọa độ lên Firebase
                    FloatingActionButton(
                      heroTag: "firebase_location",
                      mini: true,
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      onPressed: () async {
                        await _sendLocationToFirebase();
                      //   _sendLocationToFirebaseFromGetLocation
                      },
                      child: const Icon(Icons.cloud_upload),
                    ),

                    SizedBox(height: 8,),

                    // Nút kiểm tra khoảng cách tự động
                    FloatingActionButton(
                      heroTag: "check_proximity",
                      mini: true,
                      backgroundColor: _isAutoProximityChecking ? Colors.red : Colors.purple,
                      foregroundColor: Colors.white,
                      onPressed: () async {
                        _toggleAutoProximityChecking();
                      },
                      child: Icon(_isAutoProximityChecking ? Icons.stop : Icons.location_on),
                    ),

                    SizedBox(height: 8,),
                    FloatingActionButton(
                      heroTag: "orders",
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrdersScreen()),
                        );
                      },
                      child: const Icon(Icons.assignment),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          child: Column(
            children: [
              // Header with user info
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileDetailScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child:
                                authProvider.driver?.avatar?.isNotEmpty == true
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: Image.network(
                                          authProvider.driver!.avatar!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.green.shade700,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.green.shade700,
                                      ),
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            authProvider.driver?.name ?? 'Trương Xuân Kiên',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Phone
                          Text(
                            authProvider.driver?.phoneNumber ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Tap hint
                          Text(
                            '✏️ Nhấn để xem chi tiết',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      icon: Icons.home,
                      title: 'Trang chủ',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Thông tin cá nhân',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ProfileDetailScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.delivery_dining,
                      title: 'Đơn đang giao',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrdersScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.share,
                      title: 'Chia sẻ chuyến đi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TripSharingScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Thống kê',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StatisticsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.history,
                      title: 'Lịch sử chuyến đi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Mời bạn bè',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const InviteFriendsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Thiết lập',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.location_searching,
                      title: 'GPS Test',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GPSTestScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              try {
                // Stop location tracking immediately
                _locationUpdateTimer?.cancel();

                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();

                // Navigate to login with a slight delay to ensure logout completes
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PhoneInputScreen(isLogin: true),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                print('❌ Logout error: $e');
                // Still navigate to login even if logout fails
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PhoneInputScreen(isLogin: true),
                    ),
                    (route) => false,
                  );
                }
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
