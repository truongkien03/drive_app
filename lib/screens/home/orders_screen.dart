import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/distance_formatter.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Order> _inProcessOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _cancelledOrders = [];

  bool _isLoadingInProcess = false;
  bool _isLoadingCompleted = false;
  bool _isLoadingCancelled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInProcessOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInProcessOrders() async {
    if (_isLoadingInProcess) return;

    setState(() {
      _isLoadingInProcess = true;
    });

    try {
      final response = await _apiService.getInProcessOrders();
      if (response.success && response.data != null) {
        setState(() {
          _inProcessOrders = response.data!
              .map((orderData) => Order.fromJson(orderData))
              .toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải đơn hàng: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInProcess = false;
        });
      }
    }
  }

  Future<void> _loadCompletedOrders() async {
    if (_isLoadingCompleted) return;

    setState(() {
      _isLoadingCompleted = true;
    });

    try {
      final response = await _apiService.getCompletedOrders();
      if (response.success && response.data != null) {
        setState(() {
          _completedOrders = response.data!
              .map((orderData) => Order.fromJson(orderData))
              .toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải đơn hàng: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCompleted = false;
        });
      }
    }
  }

  Future<void> _loadCancelledOrders() async {
    if (_isLoadingCancelled) return;

    setState(() {
      _isLoadingCancelled = true;
    });

    try {
      final response = await _apiService.getCancelledOrders();
      if (response.success && response.data != null) {
        setState(() {
          _cancelledOrders = response.data!
              .map((orderData) => Order.fromJson(orderData))
              .toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải đơn hàng: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCancelled = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thực hiện cuộc gọi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeOrder(Order order) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận hoàn thành'),
          content:
              Text('Bạn có chắc chắn muốn hoàn thành đơn hàng #${order.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hoàn thành'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await _apiService.completeOrder(order.id);
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hoàn thành đơn hàng'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the orders list
            _loadInProcessOrders();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi hoàn thành đơn hàng: ${response.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewOnMap(Order order) {
    // TODO: Navigate to map screen with order details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xem bản đồ sẽ được phát triển'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (index) {
            switch (index) {
              case 0:
                _loadInProcessOrders();
                break;
              case 1:
                _loadCompletedOrders();
                break;
              case 2:
                _loadCancelledOrders();
                break;
            }
          },
          tabs: const [
            Tab(text: 'Đang giao'),
            Tab(text: 'Đã hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_inProcessOrders, _isLoadingInProcess, 'inprocess'),
          _buildOrdersList(_completedOrders, _isLoadingCompleted, 'completed'),
          _buildOrdersList(_cancelledOrders, _isLoadingCancelled, 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, bool isLoading, String status) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'inprocess'
                  ? Icons.local_shipping
                  : status == 'completed'
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'inprocess'
                  ? 'Không có đơn hàng đang giao'
                  : status == 'completed'
                      ? 'Chưa có đơn hàng hoàn thành'
                      : 'Không có đơn hàng bị hủy',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        switch (status) {
          case 'inprocess':
            await _loadInProcessOrders();
            break;
          case 'completed':
            await _loadCompletedOrders();
            break;
          case 'cancelled':
            await _loadCancelledOrders();
            break;
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, status);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, String status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'inprocess':
        statusColor = Colors.orange;
        statusText = 'Đang giao';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Đã hoàn thành';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Khách hàng: ${order.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerPhone,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Từ: ${order.pickupAddress}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đến: ${order.dropoffAddress}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khoảng cách: ${DistanceFormatter.format(order.distance)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.fare),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (status == 'inprocess') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(order.customerPhone),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Gọi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeOrder(order),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewOnMap(order),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Bản đồ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(order.customerPhone),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Gọi khách hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewOnMap(order),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Xem bản đồ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
