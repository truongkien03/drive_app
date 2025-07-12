import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_history.dart';
import '../../services/delivery_history_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeliveryHistoryService _historyService = DeliveryHistoryService();
  
  // State variables
  bool _isLoading = false;
  String? _error;
  DeliveryHistoryResponse? _historyData;
  DeliveryStatistics? _statistics;
  
  // Filter variables
  String? _selectedFromDate;
  String? _selectedToDate;
  int? _selectedStatus;
  int _currentPage = 1;
  final int _perPage = 15;
  bool _hasMoreData = true;
  
  // Date picker
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': null, 'label': 'Tất cả trạng thái'},
    {'value': 1, 'label': 'Chờ xử lý'},
    {'value': 2, 'label': 'Đang xử lý'},
    {'value': 3, 'label': 'Đã tới địa điểm'},
    {'value': 4, 'label': 'Đã hoàn thành'},
    {'value': 5, 'label': 'Bị hủy'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _historyService.getDeliveryHistory(
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
        status: _selectedStatus,
        page: _currentPage,
        perPage: _perPage,
        includeStats: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (refresh) {
            _historyData = response.data;
          } else {
            // Append new data to existing list
            if (_historyData == null) {
              _historyData = response.data;
            } else {
              _historyData!.data.data.addAll(response.data!.data.data);
            }
          }
          _statistics = response.data!.statistics;
          _hasMoreData = response.data!.data.data.length >= _perPage;
          _currentPage++;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Lỗi tải dữ liệu';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (_fromDate ?? DateTime.now().subtract(Duration(days: 30))) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColor.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _selectedFromDate = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _toDate = picked;
          _selectedToDate = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      _loadHistoryData(refresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedFromDate = null;
      _selectedToDate = null;
      _selectedStatus = null;
    });
    _loadHistoryData(refresh: true);
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.all(Dimension.width16),
      padding: EdgeInsets.all(Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bộ lọc',
            style: TextStyle(
              fontSize: Dimension.font_size18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: Dimension.height12),
          
          // Date filters
          Row(
            children: [
              Expanded(
                child: _buildDateFilter(
                  'Từ ngày',
                  _fromDate,
                  () => _selectDate(context, true),
                ),
              ),
              SizedBox(width: Dimension.width12),
              Expanded(
                child: _buildDateFilter(
                  'Đến ngày',
                  _toDate,
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          
          SizedBox(height: Dimension.height12),
          
          // Status filter
          DropdownButtonFormField<int?>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimension.radius8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: Dimension.width12,
                vertical: Dimension.height8,
              ),
            ),
            items: _statusOptions.map((option) {
              return DropdownMenuItem<int?>(
                value: option['value'],
                child: Text(option['label']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _loadHistoryData(refresh: true);
            },
          ),
          
          SizedBox(height: Dimension.height12),
          
          // Clear filters button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear, size: Dimension.icon20),
                  label: Text('Xóa bộ lọc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: AppColor.textPrimary,
                    padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimension.width12,
          vertical: Dimension.height12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(Dimension.radius8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Dimension.font_size12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Dimension.height4),
            Text(
              date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Chọn ngày',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                fontWeight: FontWeight.w500,
                color: date != null ? AppColor.textPrimary : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    // Debug: Hiển thị thống kê tạm thời từ dữ liệu đơn hàng
    if (_statistics == null) {
      // Tính toán thống kê từ dữ liệu đơn hàng có sẵn
      if (_historyData == null || _historyData!.data.data.isEmpty == true) {
        return SizedBox.shrink();
      }
      
      final orders = _historyData!.data.data;
      final totalOrders = orders.length;
      final completedOrders = orders.where((o) => o.statusCode == 4).length;
      final totalEarnings = orders.fold<double>(0, (sum, order) => sum + order.shippingCost);
      final completionRate = totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
      
      return Container(
        margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
        padding: EdgeInsets.all(Dimension.width16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimension.radius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Thống kê tổng quan',
                  style: TextStyle(
                    fontSize: Dimension.font_size18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Dimension.width8, vertical: Dimension.height4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimension.radius8),
                  ),
                  child: Text(
                    'Tạm thời',
                    style: TextStyle(
                      fontSize: Dimension.font_size10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            
            // Statistics grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: Dimension.width12,
              mainAxisSpacing: Dimension.height12,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Tổng đơn hàng',
                  '$totalOrders',
                  Icons.shopping_bag,
                  AppColor.primary,
                ),
                _buildStatCard(
                  'Đã hoàn thành',
                  '$completedOrders',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Tổng thu nhập',
                  _historyService.formatCurrency(totalEarnings),
                  Icons.attach_money,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Tỷ lệ hoàn thành',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Sử dụng dữ liệu từ API statistics nếu có
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      padding: EdgeInsets.all(Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê tổng quan',
            style: TextStyle(
              fontSize: Dimension.font_size18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: Dimension.height16),
          
          // Statistics grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: Dimension.width12,
            mainAxisSpacing: Dimension.height12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Tổng đơn hàng',
                '${_statistics?.overview?.totalOrders ?? 0}',
                Icons.shopping_bag,
                AppColor.primary,
              ),
              _buildStatCard(
                'Đã hoàn thành',
                '${_statistics?.overview?.completedOrders ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Tổng thu nhập',
                _historyService.formatCurrency(_statistics?.overview?.totalEarnings ?? 0.0),
                Icons.attach_money,
                Colors.orange,
              ),
              _buildStatCard(
                'Tỷ lệ hoàn thành',
                '${(_statistics?.overview?.completionRate ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Dimension.width12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimension.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Dimension.icon20),
          SizedBox(height: Dimension.height6),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimension.font_size14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Dimension.height4),
          Text(
            title,
            style: TextStyle(
              fontSize: Dimension.font_size10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16, vertical: Dimension.height8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimension.radius12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimension.radius12),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: EdgeInsets.all(Dimension.width16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimension.width8,
                      vertical: Dimension.height4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.statusCode).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimension.radius8),
                    ),
                    child: Text(
                      'Đơn #${order.id}',
                      style: TextStyle(
                        fontSize: Dimension.font_size14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.statusCode),
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimension.width8,
                      vertical: Dimension.height4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.statusCode).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimension.radius8),
                    ),
                    child: Text(
                      _historyService.getStatusText(order.statusCode),
                      style: TextStyle(
                        fontSize: Dimension.font_size12,
                        color: _getStatusColor(order.statusCode),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Dimension.height12),
              
              // Customer info
              Row(
                children: [
                  CircleAvatar(
                    radius: Dimension.width16,
                    backgroundImage: order.customerAvatar != null 
                        ? NetworkImage(order.customerAvatar!)
                        : null,
                    child: order.customerAvatar == null 
                        ? Icon(Icons.person, size: Dimension.icon20)
                        : null,
                  ),
                  SizedBox(width: Dimension.width12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName ?? order.customer.name,
                          style: TextStyle(
                            fontSize: Dimension.font_size16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        if (order.receiver.phone.isNotEmpty)
                          Text(
                            order.receiver.phone,
                            style: TextStyle(
                              fontSize: Dimension.font_size14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Dimension.height12),
              
              // Address info
              Row(
                children: [
                  Icon(Icons.location_on, size: Dimension.icon16, color: Colors.grey[600]),
                  SizedBox(width: Dimension.width8),
                  Expanded(
                    child: Text(
                      order.toAddress.desc,
                      style: TextStyle(
                        fontSize: Dimension.font_size14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Dimension.height12),
              
              // Order details
              Row(
                children: [
                  Expanded(
                    child: _buildOrderDetail(
                      'Phí giao hàng',
                      _historyService.formatCurrency(order.shippingCost),
                      Icons.local_shipping,
                    ),
                  ),
                  Expanded(
                    child: _buildOrderDetail(
                      'Khoảng cách',
                      _historyService.formatDistance(order.distance),
                      Icons.straighten,
                    ),
                  ),
                  Expanded(
                    child: _buildOrderDetail(
                      'Thời gian',
                      _historyService.calculateDeliveryTime(
                        order.driverAcceptAt,
                        order.completedAt,
                      ),
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              
              if (order.completedAt != null) ...[
                SizedBox(height: Dimension.height8),
                Text(
                  'Hoàn thành: ${_historyService.formatDateTime(order.completedAt!)}',
                  style: TextStyle(
                    fontSize: Dimension.font_size12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: Dimension.icon16, color: Colors.grey[600]),
        SizedBox(height: Dimension.height4),
        Text(
          value,
          style: TextStyle(
            fontSize: Dimension.font_size12,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Dimension.font_size10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int statusCode) {
    switch (statusCode) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Dimension.radius16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: Dimension.height12),
              width: Dimension.width40,
              height: Dimension.height4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimension.radius2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(Dimension.width16),
              child: Row(
                children: [
                  Text(
                    'Chi tiết đơn hàng #${order.id}',
                    style: TextStyle(
                      fontSize: Dimension.font_size18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer info
                    _buildDetailSection(
                      'Thông tin khách hàng',
                      [
                        _buildDetailRow('Tên', order.customerName ?? order.customer.name),
                        _buildDetailRow('SĐT', order.receiver.phone),
                        _buildDetailRow('Địa chỉ giao', order.toAddress.desc),
                      ],
                    ),
                    
                    SizedBox(height: Dimension.height16),
                    
                    // Order info
                    _buildDetailSection(
                      'Thông tin đơn hàng',
                      [
                        _buildDetailRow('Trạng thái', _historyService.getStatusText(order.statusCode)),
                        _buildDetailRow('Phí giao hàng', _historyService.formatCurrency(order.shippingCost)),
                        _buildDetailRow('Khoảng cách', _historyService.formatDistance(order.distance)),
                        if (order.driverAcceptAt != null)
                          _buildDetailRow('Nhận đơn', _historyService.formatDateTime(order.driverAcceptAt!)),
                        if (order.completedAt != null)
                          _buildDetailRow('Hoàn thành', _historyService.formatDateTime(order.completedAt!)),
                        if (order.driverRate != null)
                          _buildDetailRow('Đánh giá', '${order.driverRate}/5'),
                      ],
                    ),
                    
                    SizedBox(height: Dimension.height16),
                    
                    // Items
                    if (order.items.isNotEmpty)
                      _buildDetailSection(
                        'Sản phẩm',
                        order.items.map((item) => 
                          _buildDetailRow(
                            '${item.name} x${item.quantity}',
                            _historyService.formatCurrency(item.price),
                          )
                        ).toList(),
                      ),
                    
                    SizedBox(height: Dimension.height16),
                    
                    // Tracking history
                    if (order.tracker.isNotEmpty)
                      _buildDetailSection(
                        'Lịch sử tracking',
                        order.tracker.map((track) => 
                          _buildDetailRow(
                            _historyService.formatDateTime(track.createdAt),
                            track.note,
                          )
                        ).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Dimension.font_size16,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: Dimension.height8),
        Container(
          padding: EdgeInsets.all(Dimension.width12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(Dimension.radius8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimension.height4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: Dimension.font_size14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: Dimension.font_size14,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lịch sử giao hàng'),
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Danh sách'),
              Tab(text: 'Thống kê'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: Dimension.icon24),
              onPressed: () => _loadHistoryData(refresh: true),
              tooltip: 'Tải lại',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Danh sách đơn hàng
            _buildOrdersList(),
            
            // Tab 2: Thống kê
            _buildStatisticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: () => _loadHistoryData(refresh: true),
      child: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading && _historyData == null
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: Dimension.icon48, color: Colors.grey),
                            SizedBox(height: Dimension.height16),
                            Text(
                              _error!,
                              style: TextStyle(fontSize: Dimension.font_size16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: Dimension.height16),
                            ElevatedButton(
                              onPressed: () => _loadHistoryData(refresh: true),
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _historyData?.data.data.isEmpty == true
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: Dimension.icon48, color: Colors.grey),
                                SizedBox(height: Dimension.height16),
                                Text(
                                  'Không có lịch sử giao hàng',
                                  style: TextStyle(fontSize: Dimension.font_size16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _historyData!.data.data.length + (_hasMoreData ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _historyData!.data.data.length) {
                                // Load more indicator
                                if (_isLoading) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(Dimension.height16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              }
                              
                              final order = _historyData!.data.data[index];
                              return _buildOrderCard(order);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: Dimension.height16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatisticsCard(),
          SizedBox(height: Dimension.height16),
          
          // Additional statistics can be added here
          if (_statistics != null) ...[
            _buildDailyStatsCard(),
            SizedBox(height: Dimension.height16),
            _buildMonthlyStatsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyStatsCard() {
    if (_statistics?.dailyStats?.isEmpty == true) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      padding: EdgeInsets.all(Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê theo ngày',
            style: TextStyle(
              fontSize: Dimension.font_size18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: Dimension.height16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _statistics?.dailyStats?.length ?? 0,
            itemBuilder: (context, index) {
              final dailyStat = _statistics?.dailyStats?[index];
              if (dailyStat == null) return SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: Dimension.height4),
                leading: CircleAvatar(
                  backgroundColor: AppColor.primary.withOpacity(0.1),
                  child: Text(
                    _historyService.getDayOfWeekName((dailyStat.dayOfWeek as int?) ?? 0).substring(0, 2),
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: Dimension.font_size12,
                    ),
                  ),
                ),
                title: Text(
                  _historyService.getDayOfWeekName((dailyStat.dayOfWeek as int?) ?? 0),
                  style: TextStyle(fontSize: Dimension.font_size14),
                ),
                subtitle: Text(
                  '${dailyStat.completedOrders ?? 0}/${dailyStat.totalOrders ?? 0} đơn hoàn thành',
                  style: TextStyle(fontSize: Dimension.font_size12),
                ),
                trailing: Text(
                  _historyService.formatCurrency(dailyStat.earnings ?? 0.0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: Dimension.font_size12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard() {
    if (_statistics?.monthlyStats?.isEmpty == true) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      padding: EdgeInsets.all(Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê theo tháng',
            style: TextStyle(
              fontSize: Dimension.font_size18,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: Dimension.height16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _statistics?.monthlyStats?.length ?? 0,
            itemBuilder: (context, index) {
              final monthlyStat = _statistics?.monthlyStats?[index];
              if (monthlyStat == null) return SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: Dimension.height4),
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(
                    monthlyStat.month.toString(),
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: Dimension.font_size12,
                    ),
                  ),
                ),
                title: Text(
                  '${_historyService.getMonthName(monthlyStat.month)} ${monthlyStat.year}',
                  style: TextStyle(fontSize: Dimension.font_size14),
                ),
                subtitle: Text(
                  '${monthlyStat.completedOrders}/${monthlyStat.totalOrders} đơn hoàn thành',
                  style: TextStyle(fontSize: Dimension.font_size12),
                ),
                trailing: Text(
                  _historyService.formatCurrency(monthlyStat.earnings),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: Dimension.font_size12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
