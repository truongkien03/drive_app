import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/app_color.dart';
import '../../providers/proximity_provider.dart';
import 'proof_of_delivery_screen.dart'; // Added import for ProofOfDeliveryScreen
import 'dart:async'; // Added import for Timer
import 'dart:math'; // Added import for math functions
import '../../utils/dimension.dart';
import 'package:latlong2/latlong.dart';
import 'home_screen.dart';
import '../../services/location_order_service.dart';
import 'package:geolocator/geolocator.dart'; // Added import for Position
import 'package:flutter_background_service/flutter_background_service.dart'; // Added import for flutter_background_service
import 'package:flutter_background_service_android/flutter_background_service_android.dart'; // Added import for flutter_background_service_android

class _OrderTab {
  final String label;
  final int statusCode;
  final IconData icon;
  _OrderTab(this.label, this.statusCode, this.icon);
}

final List<_OrderTab> _tabs = [
  _OrderTab('', 2, Icons.local_shipping),
  _OrderTab('', 3, Icons.schedule),
  _OrderTab('', 4, Icons.check_circle),
  _OrderTab('', 5, Icons.cancel),
];

   Future<void> openMap(double lat, double lon, {BuildContext? context}) async {
    final googleMapsDirUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    if (await canLaunchUrl(googleMapsDirUrl)) {
      await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
  }
}

// void openGoogleMaps(double lat, double lng) async {
//   final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
//   if (await canLaunch(url)) {
//     await launch(url);
//   } else {
//     throw 'Không mở được Google Maps';
//   }
// }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // State cho từng tab
  List<Order> _ongoingOrders = [];
  List<Order> _arrivingOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _cancelledOrders = [];
  bool _isLoadingOngoing = false;
  bool _isLoadingArriving = false;
  bool _isLoadingCompleted = false;
  bool _isLoadingCancelled = false;
  String? _errorOngoing;
  String? _errorArriving;
  String? _errorCompleted;
  String? _errorCancelled;
  Set<int> _expandedOrderIds = {};

  // Thêm logic kiểm tra khoảng cách tự động cho tab Đang giao
  bool _isAutoProximityChecking = false;
  // Timer cho kiểm tra tự động
  Timer? _proximityCheckTimer;
  // Đánh dấu các đơn hàng đã "tới" để không thông báo lặp lại
  Set<int> _arrivedOrderIds = {};
  
  // Thêm các biến để quản lý dữ liệu đơn hàng như home_screen
  List<Order>? _activeOrders;
  bool _hasLoadedOrders = false;
  final LocationOrderService _logicService = LocationOrderService();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchOngoingOrders(); // Load tab đầu tiên mặc định
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && _ongoingOrders.isEmpty && !_isLoadingOngoing) {
      _fetchOngoingOrders();
    } else if (_tabController.index == 1 && _arrivingOrders.isEmpty && !_isLoadingArriving) {
      _fetchArrivingOrders();
    } else if (_tabController.index == 2 && _completedOrders.isEmpty && !_isLoadingCompleted) {
      _fetchCompletedOrders();
    } else if (_tabController.index == 3 && _cancelledOrders.isEmpty && !_isLoadingCancelled) {
      _fetchCancelledOrders();
    }
  }

  Future<void> _fetchOngoingOrders() async {
    setState(() { _isLoadingOngoing = true; _errorOngoing = null; });
    try {
      final api = ApiService();
      final response = await api.getOngoingOrders();
      setState(() {
        _ongoingOrders = response.data ?? [];
        _errorOngoing = response.message;
      });
    } catch (e) {
      setState(() { _errorOngoing = e.toString(); });
    } finally {
      setState(() { _isLoadingOngoing = false; });
    }
  }

  Future<void> _fetchArrivingOrders() async {
    setState(() { _isLoadingArriving = true; _errorArriving = null; });
    try {
      final api = ApiService();
      final response = await api.getArrivingOrdersOnly();
      setState(() {
        _arrivingOrders = response.data ?? [];
        _errorArriving = response.message;
      });
    } catch (e) {
      setState(() { _errorArriving = e.toString(); });
    } finally {
      setState(() { _isLoadingArriving = false; });
    }
  }

  Future<void> _fetchCompletedOrders() async {
    setState(() { _isLoadingCompleted = true; _errorCompleted = null; });
    try {
      final api = ApiService();
      final response = await api.getCompletedOrdersOnly();
      setState(() {
        _completedOrders = response.data ?? [];
        _errorCompleted = response.message;
      });
    } catch (e) {
      setState(() { _errorCompleted = e.toString(); });
    } finally {
      setState(() { _isLoadingCompleted = false; });
    }
  }

  Future<void> _fetchCancelledOrders() async {
    setState(() { _isLoadingCancelled = true; _errorCancelled = null; });
    try {
      final api = ApiService();
      final response = await api.getCancelledOrdersOnly();
      setState(() {
        _cancelledOrders = response.data ?? [];
        _errorCancelled = response.message;
      });
    } catch (e) {
      setState(() { _errorCancelled = e.toString(); });
    } finally {
      setState(() { _isLoadingCancelled = false; });
    }
  }

  Color _statusColor(int statusCode) {
    switch (statusCode) {
      case 2:
        return AppColor.primary;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      case 5:
        return Colors.red;
      default:
        return AppColor.textPrimary;
    }
  }

  IconData _statusIcon(int statusCode) {
    switch (statusCode) {
      case 2:
        return Icons.local_shipping;
      case 3:
        return Icons.schedule;
      case 4:
        return Icons.check_circle;
      case 5:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _statusText(int statusCode) {
    switch (statusCode) {
      case 2:
        return 'Đang giao hàng';
      case 3:
        return 'Sắp giao';
      case 4:
        return 'Đã giao';
      case 5:
        return 'Đơn hủy';
      default:
        return 'Không xác định';
    }
  }

  Widget _buildOrderCard(Order order, bool isExpanded) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width12, vertical: Dimension.height8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimension.radius12),
          onTap: () {
            setState(() {
              if (_expandedOrderIds.contains(order.id)) {
                _expandedOrderIds.remove(order.id);
              } else {
                _expandedOrderIds.add(order.id);
              }
            });
          },
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(order.statusCode).withOpacity(0.15),
                child: Icon(_statusIcon(order.statusCode), color: _statusColor(order.statusCode)),
              ),
              title: Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
            children: [
              Text(_statusText(order.statusCode), style: TextStyle(color: _statusColor(order.statusCode), fontWeight: FontWeight.bold)),
                      SizedBox(width: Dimension.width8),
                      Text('• ', style: TextStyle(color: Colors.grey.shade400)),
                      Text('${order.shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VNĐ', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  SizedBox(height: Dimension.height8),
              Text('Từ: ${order.fromAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
              Text('Đến: ${order.toAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
        ),
        if (isExpanded) _buildOrderDetails(order),
      ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimension.width16, vertical: Dimension.height8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.items.isNotEmpty) ...[
            Text('Danh sách hàng hóa:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Text('- ${item.name} x${item.quantity} (${item.price.toStringAsFixed(0)} VNĐ)')),
            SizedBox(height: Dimension.height8),
          ],
          Text('Người nhận: ${order.customer.name}'),
          if (order.customer.phone != null) Text('SĐT: ${order.customer.phone}'),
          if (order.driverAcceptAt != null) Text('Nhận đơn lúc: ${order.driverAcceptAt}'),
          if (order.createdAt != null) Text('Tạo lúc: ${order.createdAt}'),
          SizedBox(height: Dimension.height8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _onNavigationPressed(order, context),
                icon: Icon(Icons.navigation, size: Dimension.icon24),
                label: Text('Dẫn đường'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
              ),
              SizedBox(width: Dimension.width8),
              if (order.customer.phone != null)
                ElevatedButton.icon(
                  onPressed: () => _callPhone(order.customer.phone!),
                  icon: Icon(Icons.phone, size: Dimension.icon24),
                  label: Text('Gọi điện'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              SizedBox(width: Dimension.width8),
              if (order.customer.phone != null)
                ElevatedButton.icon(
                  onPressed: () => _sendSMS(order.customer.phone!),
                  icon: Icon(Icons.sms, size: Dimension.icon24),
                  label: Text('Nhắn tin'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _onNavigationPressed(Order order, BuildContext context) async {
    //Provider.of<ProximityProvider>(context, listen: false).toggleAutoProximityChecking(context);
    //Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          destination: LatLng(order.toAddress.lat, order.toAddress.lon),
        ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _sendSMS(String phone) async {
    final url = 'sms:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildOrderCardForTab(Order order, int tabIndex) {
    // Tab 0: Đang giao hàng
    if (tabIndex == 0) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: Dimension.width12, vertical: Dimension.height8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          onTap: () {
            setState(() {
              if (_expandedOrderIds.contains(order.id)) {
                _expandedOrderIds.remove(order.id);
              } else {
                _expandedOrderIds.add(order.id);
              }
            });
          },
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(order.statusCode).withOpacity(0.15),
                  child: Icon(_statusIcon(order.statusCode), color: _statusColor(order.statusCode)),
                ),
                title: Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_statusText(order.statusCode), style: TextStyle(color: _statusColor(order.statusCode), fontWeight: FontWeight.bold)),
                        SizedBox(width: Dimension.width8),
                        Text('• ', style: TextStyle(color: Colors.grey.shade400)),
                        Text('${order.shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VNĐ', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    SizedBox(height: Dimension.height8),
                    Text('Từ: ${order.fromAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
                    Text('Đến: ${order.toAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                trailing: Icon(_expandedOrderIds.contains(order.id) ? Icons.expand_less : Icons.expand_more),
              ),
              if (_expandedOrderIds.contains(order.id))
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimension.width16, vertical: Dimension.height8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin đơn hàng
                      Container(
                        padding: EdgeInsets.all(Dimension.width12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(Dimension.radius12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: Dimension.icon20, color: AppColor.primary),
                                SizedBox(width: Dimension.width8),
                                Text(
                                  'Thông tin đơn hàng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Dimension.font_size16,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimension.height12),
                            if (order.items.isNotEmpty) ...[
                              Text('Danh sách hàng hóa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: Dimension.font_size14)),
                              SizedBox(height: Dimension.height8),
                              ...order.items.map((item) => Padding(
                                padding: EdgeInsets.only(bottom: Dimension.height4),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2, size: Dimension.icon16, color: Colors.grey[600]),
                                    SizedBox(width: Dimension.width8),
                                    Expanded(
                                      child: Text(
                                        '${item.name} x${item.quantity}',
                                        style: TextStyle(fontSize: Dimension.font_size14),
                                      ),
                                    ),
                                    Text(
                                      '${item.price.toStringAsFixed(0)} VNĐ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: Dimension.font_size14,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              Divider(height: Dimension.height16),
                            ],
                            _buildInfoRow(Icons.person, 'Người nhận', order.customer.name),
                            if (order.customer.phone != null)
                              _buildInfoRow(Icons.phone, 'SĐT', order.customer.phone!),
                            if (order.driverAcceptAt != null)
                              _buildInfoRow(Icons.access_time, 'Nhận đơn lúc', order.driverAcceptAt!.toString()),
                            if (order.createdAt != null)
                              _buildInfoRow(Icons.schedule, 'Tạo lúc', order.createdAt!.toString()),
                          ],
                        ),
                      ),
                      SizedBox(height: Dimension.height16),
                      // Địa chỉ giao hàng
                      Container(
                        padding: EdgeInsets.all(Dimension.width12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(Dimension.radius12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, size: Dimension.icon20, color: Colors.blue),
                                SizedBox(width: Dimension.width8),
                                Text(
                                  'Địa chỉ giao hàng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Dimension.font_size16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimension.height12),
                            Text(
                              order.toAddress.desc,
                              style: TextStyle(
                                fontSize: Dimension.font_size14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Dimension.height16),
                      // Các nút hành động
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _onNavigationPressed(order, context),
                              icon: Icon(Icons.navigation, size: Dimension.icon20),
                              label: Text('Dẫn đường'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                              ),
                            ),
                          ),
                          SizedBox(width: Dimension.width8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Bật background service
                                final service = FlutterBackgroundService();
                                if (!(await service.isRunning())) {
                                  await service.startService();
                                }
                                // Mở Google Maps như cũ
                                await openMap(order.toAddress.lat, order.toAddress.lon, context: context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🗺️ Đã mở Google Maps. Kiểm tra tọa độ đang chạy ngầm.'),
                                      backgroundColor: Colors.blue,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.map, size: Dimension.icon20),
                              label: Text('Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimension.height12),
                      Row(
                        children: [
                          if (order.customer.phone != null) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _callPhone(order.customer.phone!),
                                icon: Icon(Icons.phone, size: Dimension.icon20),
                                label: Text('Gọi điện'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                                ),
                              ),
                            ),
                            SizedBox(width: Dimension.width8),
                          ],
                          if (order.customer.phone != null) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _sendSMS(order.customer.phone!),
                                icon: Icon(Icons.sms, size: Dimension.icon20),
                                label: Text('Nhắn tin'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                                ),
                              ),
                            ),
                            SizedBox(width: Dimension.width8),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Xác nhận hoàn thành đơn hàng
                              },
                              icon: Icon(Icons.check_circle, size: Dimension.icon20),
                              label: Text('Đã giao xong'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    // Tab 1: Sắp giao
    if (tabIndex == 1) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: Dimension.width12, vertical: Dimension.height8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          onTap: () {
            setState(() {
              if (_expandedOrderIds.contains(order.id)) {
                _expandedOrderIds.remove(order.id);
              } else {
                _expandedOrderIds.add(order.id);
              }
            });
          },
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(order.statusCode).withOpacity(0.15),
                  child: Icon(_statusIcon(order.statusCode), color: _statusColor(order.statusCode)),
                ),
                title: Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_statusText(order.statusCode), style: TextStyle(color: _statusColor(order.statusCode), fontWeight: FontWeight.bold)),
                        SizedBox(width: Dimension.width8),
                        Text('• ', style: TextStyle(color: Colors.grey.shade400)),
                        Text('${order.shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VNĐ', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    SizedBox(height: Dimension.height8),
                    Text('Từ: ${order.fromAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
                    Text('Đến: ${order.toAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                trailing: Icon(_expandedOrderIds.contains(order.id) ? Icons.expand_less : Icons.expand_more),
              ),
              if (_expandedOrderIds.contains(order.id))
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimension.width16, vertical: Dimension.height8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.items.isNotEmpty) ...[
                        Text('Danh sách hàng hóa:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...order.items.map((item) => Text('- ${item.name} x${item.quantity} (${item.price.toStringAsFixed(0)} VNĐ)')),
                        SizedBox(height: Dimension.height8),
                      ],
                      Text('Người nhận: ${order.customer.name}'),
                      if (order.customer.phone != null) Text('SĐT: ${order.customer.phone}'),
                      if (order.driverAcceptAt != null) Text('Nhận đơn lúc: ${order.driverAcceptAt}'),
                      if (order.createdAt != null) Text('Tạo lúc: ${order.createdAt}'),
                      SizedBox(height: Dimension.height8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                                                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProofOfDeliveryScreen(
                                  order: order,
                                  onOrderCompleted: () {
                                    // Refresh dữ liệu khi đơn hàng hoàn thành
                                    _fetchOngoingOrders();
                                    _fetchArrivingOrders();
                                    _fetchCompletedOrders();
                                    _fetchCancelledOrders();
                                  },
                                ),
                              ),
                            );
                            },
                            icon: Icon(Icons.assignment_turned_in, size: Dimension.icon24),
                            label: Text('Giao hàng'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
                          ),
                          SizedBox(width: Dimension.width8),
                          if (order.customer.phone != null)
                            ElevatedButton.icon(
                              onPressed: () => _callPhone(order.customer.phone!),
                              icon: Icon(Icons.phone, size: Dimension.icon24),
                              label: Text('Gọi điện'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    // Tab 2: Đã giao
    if (tabIndex == 2) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: Dimension.width12, vertical: Dimension.height8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _statusColor(order.statusCode).withOpacity(0.15),
            child: Icon(_statusIcon(order.statusCode), color: _statusColor(order.statusCode)),
          ),
          title: Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_statusText(order.statusCode), style: TextStyle(color: _statusColor(order.statusCode), fontWeight: FontWeight.bold)),
              SizedBox(height: Dimension.height8),
              Text('Từ: ${order.fromAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
              Text('Đến: ${order.toAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          trailing: ElevatedButton.icon(
            onPressed: () {
              // TODO: Xem chi tiết đơn hàng
            },
            icon: Icon(Icons.info_outline, size: Dimension.icon24),
            label: Text('Chi tiết'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
          ),
        ),
      );
    }
    // Tab 3: Đơn hủy
    if (tabIndex == 3) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: Dimension.width12, vertical: Dimension.height8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _statusColor(order.statusCode).withOpacity(0.15),
            child: Icon(_statusIcon(order.statusCode), color: _statusColor(order.statusCode)),
          ),
          title: Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_statusText(order.statusCode), style: TextStyle(color: _statusColor(order.statusCode), fontWeight: FontWeight.bold)),
              SizedBox(height: Dimension.height8),
              Text('Từ: ${order.fromAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
              Text('Đến: ${order.toAddress.desc}', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          trailing: ElevatedButton.icon(
            onPressed: () {
              // TODO: Xem lý do hủy
            },
            icon: Icon(Icons.cancel, size: Dimension.icon24),
            label: Text('Lý do'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ),
      );
    }
    // Fallback
    return _buildOrderCard(order, false);
  }

  Widget _buildTabContentV2(List<Order> orders, String emptyText, {bool isLoading = false, String? error, Future<void> Function()? onRefresh, int tabIndex = 0}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error, style: TextStyle(color: Colors.red, fontSize: Dimension.font_size16)));
    }
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: Dimension.icon24 * 2.5, color: Colors.grey.shade300),
            SizedBox(height: Dimension.height12),
            Text(emptyText, style: TextStyle(color: Colors.grey.shade600, fontSize: Dimension.font_size16)),
          ],
        ),
      );
    }
    final Future<void> Function() refresh = onRefresh ?? () async {};
    // Nếu là tab Đang giao, hiển thị nút nổi kiểm tra khoảng cách
    if (tabIndex == 0) {
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: Dimension.height8, bottom: Dimension.height16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCardForTab(order, tabIndex);
              },
            ),
          ),
          Positioned(
            bottom: Dimension.height16,
            right: Dimension.width16,
            child: FloatingActionButton(
              heroTag: "check_proximity",
              mini: true,
              backgroundColor: _isAutoProximityChecking ? Colors.red : Colors.purple,
              foregroundColor: Colors.white,
              onPressed: _toggleAutoProximityChecking,
              child: Icon(_isAutoProximityChecking ? Icons.stop : Icons.location_on, size: Dimension.icon24),
            ),
          ),
        ],
      );
    }
    // Các tab khác giữ nguyên
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        padding: EdgeInsets.only(top: Dimension.height8, bottom: Dimension.height16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCardForTab(order, tabIndex);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _proximityCheckTimer?.cancel();
    super.dispose();
  }

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
      _checkProximityToOrders();
      
      // Thiết lập timer chạy mỗi 2 giây
      _proximityCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (_isAutoProximityChecking) {
          print("📏 Đang tính khoảng cách...");
          _checkProximityToOrders();
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

  /// Load đơn hàng từ API một lần duy nhất
  Future<void> _loadOrdersOnce() async {
    try {
      print('📦 Đang tải dữ liệu đơn hàng từ API...');
      final orders = await _logicService.getOrdersWithCache();
      if (orders == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi tải đơn hàng'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      _activeOrders = orders;
      _hasLoadedOrders = true;
      _arrivedOrderIds.clear();
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
            content: Text('❌ Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Hàm kiểm tra khoảng cách đến các đơn hàng đang giao
  Future<void> _checkProximityToOrders() async {
    try {
      print('🎯 Bắt đầu kiểm tra khoảng cách đến đơn hàng...');

      // Kiểm tra xem đã load đơn hàng chưa
      if (!_hasLoadedOrders || _activeOrders == null) {
        print('❌ Chưa có dữ liệu đơn hàng, vui lòng bấm nút để load trước');
        return;
      }

      // Luôn luôn lấy vị trí mới nhất
      await _logicService.getCurrentLocation();
      _currentPosition = _logicService.currentPosition;

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

      // Lọc đơn hàng có thể kiểm tra khoảng cách (status 1, 2)
      final activeDeliveryOrders = _activeOrders!.where((order) => 
        order.statusCode == 1 || order.statusCode == 2
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
        double distance = _logicService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          order.toAddress.lat,
          order.toAddress.lon,
        );

        print('📏 Khoảng cách đến đơn hàng ${order.id}: ${distance.toStringAsFixed(2)}m');
        print('   Địa chỉ: ${order.toAddress.desc}');
        print('   Tọa độ: ${order.toAddress.lat}, ${order.toAddress.lon}');

        // Nếu khoảng cách <= 15m và chưa thông báo cho đơn này
        if (distance <= 15.0 && !_arrivedOrderIds.contains(order.id)) {
          _arrivedOrderIds.add(order.id); // Đánh dấu đã tới
          print('🎉 ĐÃ TỚI! - Đơn hàng ${order.id}');
          print('   Khách hàng: ${order.customer.name} - ${order.customer.phone}');
          print('   Khoảng cách: ${distance.toStringAsFixed(2)}m');
          print('   Địa chỉ: ${order.toAddress.desc}');

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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimension.height4),
      child: Row(
        children: [
          Icon(icon, size: Dimension.icon16, color: Colors.grey[600]),
          SizedBox(width: Dimension.width8),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(fontSize: Dimension.font_size14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đơn hàng'),
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColor.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColor.primary,
            tabs: _tabs.map((tab) {
              int idx = _tabs.indexOf(tab);
              int count = 0;
              if (idx == 0) count = _ongoingOrders.length;
              if (idx == 1) count = _arrivingOrders.length;
              if (idx == 2) count = _completedOrders.length;
              if (idx == 3) count = _cancelledOrders.length;
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: Dimension.icon16),
                    SizedBox(width: Dimension.width8),
                    Expanded(
                      child: Text(
                        tab.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: Dimension.width8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: Dimension.width8, vertical: Dimension.height2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(Dimension.radius12),
                        ),
                        child: Text('$count', style: TextStyle(color: Colors.white, fontSize: Dimension.font_size14)),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: Dimension.icon24),
              onPressed: () {
                if (_tabController.index == 0) _fetchOngoingOrders();
                if (_tabController.index == 1) _fetchArrivingOrders();
                if (_tabController.index == 2) _fetchCompletedOrders();
                if (_tabController.index == 3) _fetchCancelledOrders();
              },
              tooltip: 'Tải lại',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContentV2(_ongoingOrders, 'Không có đơn hàng đang giao', isLoading: _isLoadingOngoing, error: _errorOngoing, onRefresh: _fetchOngoingOrders, tabIndex: 0),
            _buildTabContentV2(_arrivingOrders, 'Không có đơn sắp giao', isLoading: _isLoadingArriving, error: _errorArriving, onRefresh: _fetchArrivingOrders, tabIndex: 1),
            _buildTabContentV2(_completedOrders, 'Không có đơn hoàn thành', isLoading: _isLoadingCompleted, error: _errorCompleted, onRefresh: _fetchCompletedOrders, tabIndex: 2),
            _buildTabContentV2(_cancelledOrders, 'Không có đơn bị hủy', isLoading: _isLoadingCancelled, error: _errorCancelled, onRefresh: _fetchCancelledOrders, tabIndex: 3),
          ],
        ),
      ),
    );
  }
}
