import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/driver_location_service.dart';
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

  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isOnline) {
        await _getCurrentLocation();
        await _sendLocationToServer();
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
      setState(() {
        _successfulUpdates++;
      });
      print('✅ Location sent to server successfully');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
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
