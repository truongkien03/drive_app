import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/driver_location_service.dart';

/// Widget to display driver location status and controls
class LocationStatusWidget extends StatefulWidget {
  const LocationStatusWidget({Key? key}) : super(key: key);

  @override
  State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
}

class _LocationStatusWidgetState extends State<LocationStatusWidget> {
  bool _isLocationServiceAvailable = false;
  LocationPermission _permission = LocationPermission.denied;
  Position? _currentPosition;
  String _statusText = 'Đang kiểm tra...';
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.location_searching;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      final isAvailable =
          await DriverLocationService.isLocationServiceAvailable();
      final permission = await DriverLocationService.getPermissionStatus();
      final position = await DriverLocationService.getCurrentPosition();

      setState(() {
        _isLocationServiceAvailable = isAvailable;
        _permission = permission;
        _currentPosition = position;
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
      final accuracy = DriverLocationService.getLocationAccuracyDescription(
          _currentPosition!);
      final timeSince =
          DriverLocationService.timeSinceLastUpdate ?? 'Chưa cập nhật';

      _statusText = '$accuracy • $timeSince';
      _statusColor = Colors.green;
      _statusIcon = Icons.location_on;
    } else {
      _statusText = 'Đang lấy vị trí...';
      _statusColor = Colors.blue;
      _statusIcon = Icons.location_searching;
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await DriverLocationService.requestPermission();
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
                DriverLocationService.openLocationSettings();
              },
              child: Text('Mở cài đặt'),
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
                        : () => DriverLocationService.openLocationSettings(),
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
                DriverLocationService.formatCoordinates(
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
                      DriverLocationService.isTracking ? 'Có' : 'Không',
                      DriverLocationService.isTracking
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ],
              ),
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
                        ? () => DriverLocationService.updateLocationNow()
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

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
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
            ),
          ),
        ],
      ),
    );
  }
}
