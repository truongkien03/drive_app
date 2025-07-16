import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../screens/debug/token_debug_screen.dart';

/// Widget to display driver location status and controls
class LocationStatusWidget extends StatefulWidget {
  const LocationStatusWidget({Key? key}) : super(key: key);

  @override
  State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
}

class _LocationStatusWidgetState extends State<LocationStatusWidget> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLocationServiceAvailable = false;
  LocationPermission _permission = LocationPermission.denied;
  Position? _currentPosition;
  String _statusText = 'Đang kiểm tra...';
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.location_searching;
  int _consecutiveFailures = 0;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      // Check if location services are enabled
      final isAvailable = await Geolocator.isLocationServiceEnabled();

      // Check permission status
      final permission = await Geolocator.checkPermission();

      // Get current position
      final position = await _locationService.getCurrentLocation();

      // Get location stats
      final stats = _locationService.getLocationStats();

      setState(() {
        _isLocationServiceAvailable = isAvailable;
        _permission = permission;
        _currentPosition = position;
        _consecutiveFailures = stats['consecutiveFailures'] ?? 0;
        _isTracking = stats['isTracking'] ?? false;
        _updateStatusDisplay();
      });
    } catch (e) {
      setState(() {
        _statusText = 'Lỗi kiểm tra GPS';
        _statusColor = Colors.red;
        _statusIcon = Icons.error;
      });
    }
  }

  String _getUpdateIntervalText() {
    final interval = _locationService.updateInterval;
    if (interval.inMinutes >= 1) {
      return '${interval.inMinutes} phút/lần';
    } else {
      return '${interval.inSeconds} giây/lần';
    }
  }

  void _updateStatusDisplay() {
    if (!_isLocationServiceAvailable) {
      _statusText = 'GPS chưa được bật';
      _statusColor = Colors.red;
      _statusIcon = Icons.location_disabled;
    } else if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      _statusText = 'Cần quyền truy cập vị trí';
      _statusColor = Colors.orange;
      _statusIcon = Icons.location_off;
    } else if (_currentPosition != null) {
      final accuracy =
          _getLocationAccuracyDescription(_currentPosition!.accuracy);
      final timeSince = _getCurrentLocationTime();

      if (_consecutiveFailures > 0) {
        _statusText = '$accuracy • Lỗi: $_consecutiveFailures lần';
        _statusColor = Colors.orange;
        _statusIcon = Icons.warning;
      } else {
        _statusText = '$accuracy • $timeSince';
        _statusColor = Colors.green;
        _statusIcon = Icons.location_on;
      }
    } else {
      _statusText = 'Đang lấy vị trí...';
      _statusColor = Colors.blue;
      _statusIcon = Icons.location_searching;
    }
  }

  String _getLocationAccuracyDescription(double accuracy) {
    if (accuracy <= 5) return 'Rất chính xác';
    if (accuracy <= 10) return 'Chính xác';
    if (accuracy <= 20) return 'Khá chính xác';
    return 'Kém chính xác';
  }

  String _getCurrentLocationTime() {
    if (_currentPosition?.timestamp == null) return 'Chưa cập nhật';

    final diff = DateTime.now().difference(_currentPosition!.timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    return '${diff.inHours}h trước';
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _checkLocationStatus();
    } else if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cần quyền vị trí'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ứng dụng cần quyền truy cập vị trí để:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tìm đơn hàng gần bạn'),
              Text('• Cập nhật vị trí cho khách hàng'),
              Text('• Tối ưu hóa tuyến đường giao hàng'),
              SizedBox(height: 16),
              Text(
                'Hãy bật quyền vị trí trong cài đặt để sử dụng app.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: Text('Mở cài đặt'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateIntervalDialog() {
    final currentInterval = _locationService.updateInterval;
    int selectedMinutes = currentInterval.inMinutes;
    if (selectedMinutes == 0) selectedMinutes = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Cài đặt tần suất GPS'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chọn tần suất cập nhật vị trí:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Mỗi'),
                      SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: selectedMinutes.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$selectedMinutes phút',
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMinutes = value.round();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('phút'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hiện tại: ${_getUpdateIntervalText()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lưu ý:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Tần suất thấp hơn = tiết kiệm pin hơn',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Tần suất cao hơn = vị trí chính xác hơn',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Khuyến nghị: 1-3 phút',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _locationService.setUpdateInterval(
                      Duration(minutes: selectedMinutes),
                    );
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã cài đặt tần suất cập nhật: $selectedMinutes phút/lần',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getAuthenticationStatus() {
    // Check authentication token
    if (_apiService.token == null) {
      return 'Chưa đăng nhập';
    }

    // Check if location service detected auth error
    if (!_locationService.isAuthenticationValid) {
      return 'Token hết hạn';
    }

    return 'Đã xác thực';
  }

  Color _getAuthenticationColor() {
    if (_apiService.token == null || !_locationService.isAuthenticationValid) {
      return Colors.red;
    }
    return Colors.green;
  }

  IconData _getAuthenticationIcon() {
    if (_apiService.token == null) {
      return Icons.login;
    }
    if (!_locationService.isAuthenticationValid) {
      return Icons.token;
    }
    return Icons.verified_user;
  }

  Future<void> _debugTokenState() async {
    // Debug authentication state
    _authService.debugTokenState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token debug info printed to console'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _testApiConnection() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang test API...'),
            ],
          ),
        ),
      );

      if (_currentPosition != null) {
        await _locationService.forceUpdateLocation();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test API thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không có vị trí để test'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test API thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.login, color: Colors.red),
              SizedBox(width: 8),
              Text('Cần đăng nhập lại'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Token xác thực đã hết hạn (lỗi 401).',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Để tiếp tục tracking GPS, bạn cần:'),
              SizedBox(height: 8),
              Text('1. Đăng xuất khỏi app'),
              Text('2. Đăng nhập lại với tài khoản'),
              Text('3. Khởi động lại location tracking'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lỗi: 401 Unauthenticated\nEndpoint: /api/driver/current-location',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset authentication status để có thể thử lại
                _locationService.resetAuthenticationStatus();
                setState(() {});
              },
              child: Text('Tôi đã đăng nhập lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusIcon,
                  color: _statusColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái GPS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLocationServiceAvailable ||
                    _permission == LocationPermission.denied)
                  ElevatedButton.icon(
                    onPressed: _isLocationServiceAvailable
                        ? _requestLocationPermission
                        : () => Geolocator.openLocationSettings(),
                    icon: Icon(Icons.settings, size: 16),
                    label: Text('Cài đặt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            if (_currentPosition != null) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.my_location, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Vị trí hiện tại',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _formatCoordinates(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Độ chính xác',
                      '${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                      Icons.gps_fixed,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Đang theo dõi',
                      _isTracking ? 'Có' : 'Không',
                      _isTracking ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Tần suất cập nhật',
                      _getUpdateIntervalText(),
                      Icons.schedule,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Lỗi liên tiếp',
                      '$_consecutiveFailures lần',
                      _consecutiveFailures > 0
                          ? Icons.error
                          : Icons.check_circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'API Database',
                      'POST /current-location',
                      Icons.cloud_upload,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Authentication',
                      _getAuthenticationStatus(),
                      _getAuthenticationIcon(),
                      color: _getAuthenticationColor(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showUpdateIntervalDialog,
                      icon: Icon(Icons.settings, size: 16),
                      label: Text('Cài đặt tần suất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testApiConnection,
                      icon: Icon(Icons.api, size: 16),
                      label: Text('Test API'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _debugTokenState,
                      icon: Icon(Icons.bug_report, size: 16),
                      label: Text('Debug Token'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _apiService.debugTokenAndHeaders(),
                      icon: Icon(Icons.code, size: 16),
                      label: Text('Debug Headers'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _authService.debugTokenState(),
                      icon: Icon(Icons.security, size: 16),
                      label: Text('Debug Token'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TokenDebugScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.bug_report, size: 16),
                      label: Text('Full Debug'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Quy trình gửi dữ liệu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Lấy GPS → 2. POST /api/driver/current-location → 3. Lưu vào DB',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Tự động retry 3 lần nếu lỗi, dừng tạm thời nếu lỗi liên tiếp',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            // Authentication Error Panel
            if (!_locationService.isAuthenticationValid) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Token hết hạn - Cần đăng nhập lại',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Server trả về lỗi 401 Unauthenticated. Token đăng nhập đã hết hạn.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Show dialog to re-login
                              _showReLoginDialog();
                            },
                            icon: Icon(Icons.login, size: 16),
                            label: Text('Đăng nhập lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_consecutiveFailures > 0) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Có $_consecutiveFailures lần lỗi liên tiếp',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _resetLocationService,
                      icon: Icon(Icons.refresh),
                      label: Text('Khởi động lại dịch vụ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              if (_consecutiveFailures > 0) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.red, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Debug: API Failure Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lỗi: $_consecutiveFailures lần liên tiếp',
                        style: TextStyle(fontSize: 11, color: Colors.red[700]),
                      ),
                      Text(
                        'Auth: ${_getAuthenticationStatus()}',
                        style: TextStyle(fontSize: 11, color: Colors.red[700]),
                      ),
                      Text(
                        'Token: ${_apiService.token != null ? "Có (${_apiService.token!.length} chars)" : "Không có"}',
                        style: TextStyle(fontSize: 11, color: Colors.red[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kiểm tra: Console logs để xem chi tiết lỗi',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _checkLocationStatus,
                    icon: Icon(Icons.refresh),
                    label: Text('Làm mới'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentPosition != null
                        ? () => _forceUpdateLocation()
                        : null,
                    icon: Icon(Icons.send),
                    label: Text('Cập nhật ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon,
      {Color? color}) {
    final chipColor = color ?? Colors.grey[600];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: chipColor),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  Future<void> _forceUpdateLocation() async {
    try {
      await _locationService.forceUpdateLocation();
      await _checkLocationStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật vị trí thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật vị trí: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetLocationService() async {
    try {
      await _locationService.resetAndRestart();
      await _checkLocationStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khởi động lại dịch vụ vị trí'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi động lại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
