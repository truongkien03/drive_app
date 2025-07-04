import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/driver_location_service.dart';
import '../utils/gps_test_helper.dart';
import '../utils/current_location_debugger.dart';

class GPSTestScreen extends StatefulWidget {
  const GPSTestScreen({Key? key}) : super(key: key);

  @override
  State<GPSTestScreen> createState() => _GPSTestScreenState();
}

class _GPSTestScreenState extends State<GPSTestScreen> {
  Position? _currentPosition;
  String _statusText = 'Chưa lấy vị trí';
  String _apiResponseText = 'Chưa gửi API';
  bool _isLoading = false;
  bool _isLocationServiceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;
  String? _driverToken;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _loadDriverToken();
  }

  Future<void> _loadDriverToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      setState(() {
        _driverToken = token;
      });
      print('🔑 Driver token loaded: ${_driverToken?.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error loading driver token: $e');
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _permission = permission;
      });

      if (!serviceEnabled) {
        setState(() {
          _statusText = '❌ GPS chưa được bật trên thiết bị';
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusText = '❌ Quyền truy cập vị trí bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusText = '❌ Quyền truy cập vị trí bị từ chối vĩnh viễn';
        });
        return;
      }

      setState(() {
        _statusText = '✅ GPS và quyền truy cập đã sẵn sàng';
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ Lỗi kiểm tra GPS: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS chưa được bật!')),
      );
      return;
    }

    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cần quyền truy cập vị trí!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '📍 Đang lấy vị trí hiện tại...';
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _statusText = '✅ Đã lấy được vị trí hiện tại';
        _isLoading = false;
      });

      print('📍 Current position: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Speed: ${position.speed}km/h');
      print('📍 Timestamp: ${position.timestamp}');
    } catch (e) {
      setState(() {
        _statusText = '❌ Lỗi lấy vị trí: $e';
        _isLoading = false;
      });
      print('❌ Error getting location: $e');
    }
  }

  Future<void> _sendLocationToServer() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa có vị trí để gửi!')),
      );
      return;
    }

    if (_driverToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa có token xác thực!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _apiResponseText = '🌐 Đang gửi vị trí lên server...';
    });

    try {
      final url = '${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}';
      print('🌐 Sending location to: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $_driverToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'lat': _currentPosition!.latitude,
              'lon': _currentPosition!.longitude,
            }),
          )
          .timeout(Duration(seconds: 15));

      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiResponseText =
              '✅ Gửi thành công!\nServer response: ${jsonEncode(responseData)}';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _apiResponseText =
              '🔒 Unauthorized - Token hết hạn hoặc không hợp lệ';
          _isLoading = false;
        });
      } else if (response.statusCode == 422) {
        setState(() {
          _apiResponseText = '❌ Dữ liệu không hợp lệ:\n${response.body}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _apiResponseText =
              '❌ Lỗi server (${response.statusCode}):\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _apiResponseText = '❌ Lỗi kết nối: $e';
        _isLoading = false;
      });
      print('❌ Error sending location: $e');
    }
  }

  Future<void> _testLocationService() async {
    setState(() {
      _isLoading = true;
      _statusText = '🔄 Đang test location service...';
    });

    try {
      // Test using the location service
      await DriverLocationService.updateLocationNow();
      setState(() {
        _statusText = '✅ Location service test completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ Location service test failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Trạng thái GPS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'GPS Service: ${_isLocationServiceEnabled ? "✅ Bật" : "❌ Tắt"}'),
                    Text('Quyền truy cập: ${_getPermissionText(_permission)}'),
                    Text(
                        'Driver Token: ${_driverToken != null ? "✅ Có" : "❌ Không"}'),
                    SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusText.startsWith('✅')
                            ? Colors.green
                            : _statusText.startsWith('❌')
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Current Location Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Vị trí hiện tại',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_currentPosition != null) ...[
                      Text(
                          'Vĩ độ: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                      Text(
                          'Kinh độ: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                      Text(
                          'Độ chính xác: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                      Text(
                          'Tốc độ: ${_currentPosition!.speed.toStringAsFixed(1)}m/s'),
                      Text('Thời gian: ${_currentPosition!.timestamp}'),
                    ] else ...[
                      Text('Chưa có dữ liệu vị trí'),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // API Response Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 API Response',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _apiResponseText,
                      style: TextStyle(
                        color: _apiResponseText.startsWith('✅')
                            ? Colors.green
                            : _apiResponseText.startsWith('❌')
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.location_searching),
              label: Text('Lấy vị trí hiện tại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: (_isLoading || _currentPosition == null)
                  ? null
                  : _sendLocationToServer,
              icon: Icon(Icons.send),
              label: Text('Gửi vị trí lên server'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLocationService,
              icon: Icon(Icons.bug_report),
              label: Text('Test Location Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
            ),

            SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _checkLocationStatus,
              icon: Icon(Icons.refresh),
              label: Text('Refresh Status'),
            ),

            SizedBox(height: 16),

            // Advanced Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await GPSTestHelper.testCurrentLocationAPI();
                    },
                    icon: Icon(Icons.api),
                    label: Text('Test API'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await GPSTestHelper.runCompleteTest();
                    },
                    icon: Icon(Icons.science),
                    label: Text('Full Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () {
                GPSTestHelper.printAPISpecification();
              },
              icon: Icon(Icons.info_outline),
              label: Text('Show API Specification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            // Debug current_location null issue
            ElevatedButton.icon(
              onPressed: () async {
                await CurrentLocationDebugger.debugCurrentLocationIssue();
              },
              icon: Icon(Icons.bug_report),
              label: Text('Debug current_location null'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () async {
                await CurrentLocationDebugger.quickFixCurrentLocation();
              },
              icon: Icon(Icons.healing),
              label: Text('Quick Fix Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 24),

            // Debug Info
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Debug Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'API Endpoint: ${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}'),
                    Text(
                        'Location Service Tracking: ${DriverLocationService.isTracking}'),
                    Text(
                        'Last Known Position: ${DriverLocationService.lastKnownPosition != null ? "✅" : "❌"}'),
                    Text(
                        'Time Since Last Update: ${DriverLocationService.timeSinceLastUpdate ?? "N/A"}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPermissionText(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return '✅ Luôn luôn';
      case LocationPermission.whileInUse:
        return '✅ Khi sử dụng app';
      case LocationPermission.denied:
        return '❌ Từ chối';
      case LocationPermission.deniedForever:
        return '❌ Từ chối vĩnh viễn';
      case LocationPermission.unableToDetermine:
        return '❓ Không xác định';
    }
  }
}
