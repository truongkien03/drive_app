import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/driver_location_service.dart';

class RealTimeMapScreen extends StatefulWidget {
  const RealTimeMapScreen({Key? key}) : super(key: key);

  @override
  State<RealTimeMapScreen> createState() => _RealTimeMapScreenState();
}

class _RealTimeMapScreenState extends State<RealTimeMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  Timer? _mapUpdateTimer;
  String _locationStatus = 'Đang khởi tạo...';
  String _lastUpdateTime = '';
  bool _isMapReady = false;
  List<LatLng> _locationHistory = [];
  int _totalUpdates = 0;
  int _successfulUpdates = 0;
  String _accuracy = '';

  // Default location (Hanoi)
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    // Check if driver is online first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isOnline) {
      setState(() {
        _locationStatus = 'Tài xế đang offline - không tracking GPS';
      });
      return;
    }

    try {
      setState(() {
        _locationStatus = 'Đang kiểm tra quyền GPS...';
      });

      // Check location permissions
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
          _locationStatus =
              'Quyền GPS bị từ chối vĩnh viễn - vui lòng bật trong cài đặt';
        });
        return;
      }

      setState(() {
        _locationStatus = 'Đang lấy vị trí hiện tại...';
      });

      // Get initial position
      await _getCurrentLocation();

      // Start continuous tracking
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
        _accuracy = _getAccuracyDescription(position.accuracy);
        _lastUpdateTime = DateTime.now().toString().substring(11, 19);
      });

      // Add to history
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      _locationHistory.add(newPoint);

      // Keep only last 50 points
      if (_locationHistory.length > 50) {
        _locationHistory.removeAt(0);
      }

      // Move map to current location if this is first position
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
    // Update location every 30 seconds
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Only track if driver is online
      if (authProvider.isOnline) {
        await _getCurrentLocation();
        await _sendLocationToServer();
      } else {
        setState(() {
          _locationStatus = 'Tài xế offline - tạm dừng tracking';
        });
        timer.cancel();
      }
    });

    // Update map display every 5 seconds
    _mapUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Trigger UI refresh
        });
      }
    });
  }

  Future<void> _sendLocationToServer() async {
    if (_currentPosition == null) return;

    try {
      _totalUpdates++;

      // Use DriverLocationService to send to server
      await DriverLocationService.updateLocationNow();

      setState(() {
        _successfulUpdates++;
      });

      print('✅ Location sent to server successfully');
    } catch (e) {
      print('❌ Failed to send location to server: $e');
    }
  }

  String _getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) return 'Rất chính xác (${accuracy.toStringAsFixed(1)}m)';
    if (accuracy <= 10) return 'Chính xác (${accuracy.toStringAsFixed(1)}m)';
    if (accuracy <= 20) return 'Tương đối (${accuracy.toStringAsFixed(1)}m)';
    return 'Kém chính xác (${accuracy.toStringAsFixed(1)}m)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracking'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _currentPosition != null
                ? () {
                    _mapController.move(
                        LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        16.0);
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _getCurrentLocation();
              await _sendLocationToServer();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              // Status Panel
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      authProvider.isOnline ? Colors.green[50] : Colors.red[50],
                  border: Border(
                    bottom: BorderSide(
                      color: authProvider.isOnline ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          authProvider.isOnline
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color:
                              authProvider.isOnline ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          authProvider.isOnline
                              ? 'ONLINE - GPS TRACKING'
                              : 'OFFLINE - NO TRACKING',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: authProvider.isOnline
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('📍 ${"Trạng thái: " + _locationStatus}'),
                    if (_currentPosition != null) ...[
                      Text(
                          '📌 Vị trí: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                      Text('🎯 Độ chính xác: $_accuracy'),
                      Text('⏰ Cập nhật lúc: $_lastUpdateTime'),
                      Text(
                          '📊 API calls: $_successfulUpdates/$_totalUpdates thành công'),
                    ],
                  ],
                ),
              ),

              // Map
              Expanded(
                child: FlutterMap(
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

                    // Location history polyline
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
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
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
                        ],
                      ),
                  ],
                ),
              ),

              // Control Panel
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: authProvider.isOnline
                            ? null
                            : () async {
                                final success =
                                    await authProvider.setDriverOnline();
                                if (success) {
                                  _initializeLocationTracking();
                                }
                              },
                        icon: Icon(Icons.play_arrow),
                        label: Text('Bật Online'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !authProvider.isOnline
                            ? null
                            : () async {
                                await authProvider.setDriverOffline();
                                _locationUpdateTimer?.cancel();
                                _mapUpdateTimer?.cancel();
                                setState(() {
                                  _locationStatus = 'Đã dừng tracking GPS';
                                });
                              },
                        icon: Icon(Icons.stop),
                        label: Text('Offline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
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
}
