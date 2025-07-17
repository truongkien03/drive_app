import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
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
import '../../test/gps_test_screen.dart';
import 'proof_of_delivery_screen.dart';
import '../../services/location_order_service.dart';
import '../../utils/dimension.dart';
import '../../utils/app_color.dart';
import 'drawer_menu.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final LatLng? destination;
  const HomeScreen({Key? key, this.destination}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationOrderService _logicService = LocationOrderService();
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  List<LatLng> _locationHistory = [];
  String _locationStatus = 'Đang khởi tạo GPS...';
  String _lastUpdateTime = '';
  bool _isMapReady = false;
  int _totalUpdates = 0;
  int _successfulUpdates = 0;
  bool _isInitialLocationLoaded = false; // Thêm biến theo dõi vị trí ban đầu

  // Cached orders data
  List<Order>? _cachedOrders;
  DateTime? _lastOrdersFetchTime;
  static const Duration _ordersCacheDuration = Duration(minutes: 5);

  // Auto proximity checking
  Timer? _proximityCheckTimer;
  bool _isAutoProximityChecking = false;
  List<Order>? _activeOrders;
  bool _hasLoadedOrders = false;
  Set<int> _arrivedOrders = {};
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureCurrentPositionOnStartup();
      _checkAndStartTracking();
    });
  }

  Future<void> _ensureCurrentPositionOnStartup() async {
    await _logicService.getCurrentLocation();
    setState(() {
      _currentPosition = _logicService.currentPosition;
      _isInitialLocationLoaded = true; // Đánh dấu vị trí ban đầu đã được load
    });
    // Tự động di chuyển bản đồ đến vị trí hiện tại nếu có
    if (_currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        );
        print('📍 Map moved to current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    });
    }
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
      await _logicService.getCurrentLocation();
      setState(() {
        _currentPosition = _logicService.currentPosition;
        _locationStatus = 'GPS đang hoạt động';
      });
      // Tự động di chuyển bản đồ đến vị trí hiện tại
      if (_currentPosition != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            16.0,
          );
          print('📍 Map moved to current position after GPS initialization: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        });
      }
      _startLocationTracking();
    } catch (e) {
      setState(() {
        _locationStatus = 'Lỗi khởi tạo GPS: $e';
      });
    }
  }

  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isOnline) {
        await _logicService.getCurrentLocation(updateHistory: true); // luôn update history
        setState(() {
          _currentPosition = _logicService.currentPosition;
          _locationHistory = List.from(_logicService.locationHistory);
        });
        await _sendLocationToFirebase();
      } else {
        setState(() {
          _locationStatus = 'Tài xế offline - dừng tracking';
          _locationHistory = List.from(_logicService.locationHistory);
        });
        timer.cancel();
      }
    });
  }

  Future<void> _sendLocationToFirebase() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverId = authProvider.driver?.id?.toString() ?? 'unknown';
      final position = _logicService.currentPosition;
      if (position != null) {
        await _logicService.sendLocationToFirebase(driverId, position);
        setState(() {
          _lastUpdateTime = DateTime.now().toString().substring(11, 19);
          _successfulUpdates++;
          _totalUpdates++;
        });
      }
    } catch (e) {
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

  Future<void> _loadOrdersOnce() async {
    try {
      final api = ApiService();
      final response = await api.getDriverOrders();
      if (!response.success || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi tải đơn hàng: ${response.message ?? "Không rõ lỗi"}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      _activeOrders = response.data;
      _hasLoadedOrders = true;
      _arrivedOrders.clear();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return _logicService.calculateDistance(lat1, lon1, lat2, lon2);
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
  /// _toggleAutoProximityChecking
  Future<void> _checkProximityToDestination() async {
    try {
      print('Bắt đầu kiểm tra khoảng cách...');

      // Kiểm tra xem đã load đơn hàng chưa
      if (!_hasLoadedOrders || _activeOrders == null) {
        print('❌ Chưa có dữ liệu đơn hàng, vui lòng bấm nút để load trước');
        return;
      }

      // // Lấy vị trí hiện tại
      // if (_currentPosition == null) {
      //   _currentPosition = await _logicService.getCurrentLocation();
      // }
      //
      // if (_currentPosition == null) {
      //   print('❌ Không thể lấy vị trí hiện tại');
      //   return;
      // }
      //
      // print('📍 Vị trí hiện tại: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

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
        // Dừng kiểm tra khoảng cách tự động
        if (_isAutoProximityChecking) {
          _isAutoProximityChecking = false;
          _proximityCheckTimer?.cancel();
          _proximityCheckTimer = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⏹️ Đã dừng kiểm tra khoảng cách tự động (không còn đơn hàng)'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        return;
      }

      print('📦 Đang kiểm tra ${activeDeliveryOrders.length} đơn hàng đang giao');

      // Kiểm tra từng đơn hàng
      for (final order in activeDeliveryOrders) {
        print('🚚 Kiểm tra đơn hàng ${order.id} (trạng thái: ${order.statusCode})');
        _currentPosition = await _logicService.getCurrentLocation(updateHistory: true); // luôn update history
        setState(() {
          _locationHistory = List.from(_logicService.locationHistory);
        });
        if (_currentPosition != null) {
          try {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              16.0,
            );
          } catch (e) {
            // Có thể _mapController chưa sẵn sàng, bỏ qua lỗi
          }
        }
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

        // Nếu khoảng cách <= 15m và chưa được đánh dấu là đã tới
        if (distance <= 50.0 && !_arrivedOrders.contains(order.id)) {
          print('   ĐÃ TỚI! - Đơn hàng ${order.id}');
          print('   Khách hàng: ${order.customer.name} - ${order.customer.phone}');
          print('   Khoảng cách: ${distance.toStringAsFixed(2)}m');
          print('   Địa chỉ: ${order.toAddress.desc}');

          // Đánh dấu đơn hàng này đã được xử lý
          _arrivedOrders.add(order.id);

          // Không clear _locationHistory ở đây để giữ đường đi
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProofOfDeliveryScreen(
                  order: order,
                  onOrderCompleted: () {
                    _loadOrdersOnce();
                  },
                ),
              ),
            );
          }

          // Cập nhật trạng thái lên server
          await _updateOrderArrivedStatus(order.id, distance);

          // Hiển thị thông báo trên UI
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('🎉 ĐÃ TỚI địa chỉ giao hàng!\nKhoảng cách: ${distance.toStringAsFixed(1)}m\nKhách hàng: ${order.customer.name}'),
          //       backgroundColor: Colors.green,
          //       duration: Duration(seconds: 5),
          //       action: SnackBarAction(
          //         label: 'Chi tiết',
          //         textColor: Colors.white,
          //         onPressed: () {
          //           // Có thể mở màn hình chi tiết đơn hàng
          //         },
          //       ),
          //     ),
          //   );
          // }
        }
      }

    } catch (e) {
      print('❌ Lỗi khi kiểm tra khoảng cách: $e');
    }
  }

  /// Bật/tắt chế độ kiểm tra khoảng cách tự động
  void _toggleAutoProximityChecking() async {
    if (_isAutoProximityChecking) {
      // Tắt chế độ tự động
      _proximityCheckTimer?.cancel();
      _proximityCheckTimer = null;
      _isAutoProximityChecking = false;
      

    } else {
      // Kiểm tra xem đã load đơn hàng chưa
      if (!_hasLoadedOrders) {
        print('📦 Chưa có dữ liệu đơn hàng, đang tải...');

        // Load đơn hàng trước
        await _loadOrdersOnce();


        // Kiểm tra lại sau khi load
        if (!_hasLoadedOrders) {
          print('❌ Không thể tải đơn hàng, không thể bật kiểm tra tự động');
          return;
        }
      }

      await _loadOrdersOnce();

      // Bật chế độ tự động
      _isAutoProximityChecking = true;
      
      // Chạy kiểm tra ngay lập tức
      _checkProximityToDestination();
      
      // Thiết lập timer chạy mỗi 2 giây
      _proximityCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (_isAutoProximityChecking) {
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
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
    
    // Cập nhật UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      drawer: DrawerMenu(onLogout: _logout),
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
              _isInitialLocationLoaded && _currentPosition != null
                  ? FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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
                  // Vẽ đường đi từ vị trí hiện tại đến điểm giao hàng tiếp theo
                  if (_currentPosition != null && _activeOrders != null) ...{
                    // Lấy đơn hàng đầu tiên đang giao
                    if (_activeOrders!.where((order) => _canCheckProximity(order.statusCode)).isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              LatLng(
                                _activeOrders!.where((order) => _canCheckProximity(order.statusCode)).first.toAddress.lat,
                                _activeOrders!.where((order) => _canCheckProximity(order.statusCode)).first.toAddress.lon,
                              ),
                            ],
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                  },

                  // MarkerLayer: vị trí tài xế + vị trí khách hàng
                  MarkerLayer(
                    markers: [
                      // Marker vị trí hiện tại của tài xế
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
                            // Marker vị trí cần đến (destination)
                            if (widget.destination != null)
                              Marker(
                                point: widget.destination!,
                                child: Container(
                                  child: Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ),
                      // Marker vị trí khách hàng (toAddress của các đơn hàng đang giao)
                      if (_activeOrders != null && _activeOrders!.isNotEmpty)
                        ..._activeOrders!
                          .where((order) => _canCheckProximity(order.statusCode))
                          .map((order) => Marker(
                                point: LatLng(order.toAddress.lat, order.toAddress.lon),
                                child: Container(
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ))
                          .toList(),

                      // Các marker mẫu khác (nếu cần)
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
                    )
                  : Container(
                      // Hiển thị loading khi chưa có vị trí
                      color: Colors.grey[100],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Đang tải vị trí GPS...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _locationStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _ensureCurrentPositionOnStartup();
                              },
                              icon: Icon(Icons.my_location),
                              label: Text('Thử lại GPS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          EdgeInsets.symmetric(horizontal: Dimension.width16, vertical: Dimension.height12),
                      decoration: BoxDecoration(
                        color: authProvider.isOnline
                            ? Colors.green[50]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(Dimension.radius12),
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
                                    fontSize: Dimension.font_size16,
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
                                        fontSize: Dimension.font_size14, color: Colors.grey[600]),
                                  )
                                else if (authProvider.isOnline)
                                  Text(
                                    _locationStatus,
                                    style: TextStyle(
                                        fontSize: Dimension.font_size14, color: Colors.grey[600]),
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
                top: 150,
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
                bottom: 30,
                left: 75,
                right: 75,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimension.radius12),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: Dimension.font_size14,
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
                      onPressed: () {
                        getCurrentLocationOnly();
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            16.0,
                          );
                        }
                      },
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

  /// Hàm lấy vị trí hiện tại, hiển thị vị trí trên bản đồ nhưng không lưu vào history
  Future<void> getCurrentLocationOnly() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = position;
        _isInitialLocationLoaded = true; // Đánh dấu vị trí đã được load
        _locationHistory = List.from(_logicService.locationHistory); // Đồng bộ lịch sử
      });
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16.0,
      );
      print('📍 GPS Updated (only): ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error getting current location (only): $e');
    }
  }
}
