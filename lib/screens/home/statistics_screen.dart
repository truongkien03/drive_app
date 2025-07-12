import 'package:flutter/material.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import '../../services/statistics_service.dart';
import '../../models/statistics.dart';
import '../../models/api_response.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  ShipperStatistics? _statistics;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ApiResponse<ShipperStatistics> response;
      
      switch (_selectedPeriod) {
        case 'daily':
          response = await _statisticsService.getDailyStatistics();
          break;
        case 'weekly':
          response = await _statisticsService.getWeeklyStatistics();
          break;
        default:
          response = await _statisticsService.getMonthlyStatistics();
      }

      if (response.success && response.data != null) {
        setState(() {
          _statistics = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Lỗi tải thống kê';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Thống kê',
          style: TextStyle(
            fontSize: Dimension.font_size18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: Dimension.icon24),
            onPressed: _loadStatistics,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
          ),
          SizedBox(height: Dimension.height16),
          Text(
            'Đang tải thống kê...',
            style: TextStyle(
              fontSize: Dimension.font_size16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Dimension.icon24 * 2,
            color: Colors.red,
          ),
          SizedBox(height: Dimension.height16),
          Text(
            'Lỗi tải thống kê',
            style: TextStyle(
              fontSize: Dimension.font_size16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: Dimension.height8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: Dimension.font_size14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimension.height20),
          ElevatedButton(
            onPressed: _loadStatistics,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_statistics == null) return _buildErrorState();

    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimension.width16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          SizedBox(height: Dimension.height20),
          
          // Shipper info card
          _buildShipperInfoCard(),
          SizedBox(height: Dimension.height20),
          
          // Main stats cards
          _buildMainStatsCards(),
          SizedBox(height: Dimension.height20),
          
          // Growth indicators
          _buildGrowthIndicators(),
          SizedBox(height: Dimension.height20),
          
          // Performance metrics
          _buildPerformanceMetrics(),
          SizedBox(height: Dimension.height20),
          
          // Daily performance chart
          _buildDailyPerformanceChart(),
          SizedBox(height: Dimension.height20),
          
          // Top areas
          _buildTopAreas(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width12),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColor.primary,
              size: Dimension.icon20,
            ),
            SizedBox(width: Dimension.width8),
            Text(
              'Thời gian:',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: Dimension.width12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isExpanded: true,
                underline: Container(),
                items: [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text('Ngày'),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text('Tuần'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Tháng'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                    _loadStatistics();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipperInfoCard() {
    final shipper = _statistics!.shipperInfo;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Container(
        padding: EdgeInsets.all(Dimension.width16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Dimension.radius12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: Dimension.width20,
              backgroundImage: NetworkImage(shipper.avatar),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image error
              },
              child: shipper.avatar.isEmpty
                  ? Icon(Icons.person, color: Colors.white, size: Dimension.icon24)
                  : null,
            ),
            SizedBox(width: Dimension.width12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipper.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Dimension.font_size16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Dimension.height4),
                  Text(
                    shipper.phone,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: Dimension.font_size14,
                    ),
                  ),
                  SizedBox(height: Dimension.height4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimension.width8,
                          vertical: Dimension.height2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(_statisticsService.getShipperStatusColor(shipper.status)),
                          borderRadius: BorderRadius.circular(Dimension.radius8),
                        ),
                        child: Text(
                          _statisticsService.getShipperStatus(shipper.status),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Dimension.font_size12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (shipper.rating != null) ...[
                        SizedBox(width: Dimension.width8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: Dimension.icon16,
                            ),
                            SizedBox(width: Dimension.width4),
                            Text(
                              shipper.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Dimension.font_size12,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildMainStatsCards() {
    final current = _statistics!.currentPeriod;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng thu nhập',
                '${_statisticsService.formatCurrency(current.totalEarnings)} VNĐ',
                Icons.monetization_on,
                Colors.orange,
              ),
            ),
            SizedBox(width: Dimension.width12),
            Expanded(
              child: _buildStatCard(
                'Thực nhận',
                '${_statisticsService.formatCurrency(current.commissionEarned)} VNĐ',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: Dimension.height12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng đơn hàng',
                '${current.totalOrders}',
                Icons.shopping_bag,
                Colors.blue,
              ),
            ),
            SizedBox(width: Dimension.width12),
            Expanded(
              child: _buildStatCard(
                'Hoàn thành',
                '${current.completedOrders}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: Dimension.height12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tỷ lệ hoàn thành',
                '${current.completionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            SizedBox(width: Dimension.width12),
            Expanded(
              child: _buildStatCard(
                'Đánh giá TB',
                current.averageRating > 0 
                    ? current.averageRating.toStringAsFixed(1)
                    : 'N/A',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width12),
        child: Column(
          children: [
            Icon(icon, color: color, size: Dimension.icon24),
            SizedBox(height: Dimension.height8),
            Text(
              value,
              style: TextStyle(
                fontSize: Dimension.font_size16,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimension.height4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: Dimension.font_size12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthIndicators() {
    final growth = _statistics!.growth;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tăng trưởng so với kỳ trước',
              style: TextStyle(
                fontSize: Dimension.font_size16,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: Dimension.height16),
            Row(
              children: [
                Expanded(
                  child: _buildGrowthCard(
                    'Thu nhập',
                    _statisticsService.getGrowthText(growth.earningsGrowth),
                    _statisticsService.getGrowthIcon(growth.earningsGrowth),
                    Color(_statisticsService.getGrowthColor(growth.earningsGrowth)),
                  ),
                ),
                SizedBox(width: Dimension.width12),
                Expanded(
                  child: _buildGrowthCard(
                    'Đơn hàng',
                    _statisticsService.getGrowthText(growth.ordersGrowth),
                    _statisticsService.getGrowthIcon(growth.ordersGrowth),
                    Color(_statisticsService.getGrowthColor(growth.ordersGrowth)),
                  ),
                ),
                SizedBox(width: Dimension.width12),
                Expanded(
                  child: _buildGrowthCard(
                    'Đánh giá',
                    _statisticsService.getGrowthText(growth.ratingImprovement),
                    _statisticsService.getGrowthIcon(growth.ratingImprovement),
                    Color(_statisticsService.getGrowthColor(growth.ratingImprovement)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(String title, String value, String icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Dimension.width12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimension.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: Dimension.font_size20),
          ),
          SizedBox(height: Dimension.height4),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimension.font_size14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: Dimension.height2),
          Text(
            title,
            style: TextStyle(
              fontSize: Dimension.font_size12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final metrics = _statistics!.performanceMetrics;
    final current = _statistics!.currentPeriod;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chỉ số hiệu suất',
              style: TextStyle(
                fontSize: Dimension.font_size16,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: Dimension.height16),
            _buildMetricRow(
              'Giá trị đơn hàng TB',
              '${_statisticsService.formatCurrency(metrics.averageOrderValue)} VNĐ',
              Icons.attach_money,
            ),
            Divider(height: Dimension.height16),
            _buildMetricRow(
              'Đơn hàng/ngày',
              '${metrics.ordersPerDay.toStringAsFixed(1)}',
              Icons.schedule,
            ),
            Divider(height: Dimension.height16),
            _buildMetricRow(
              'Thu nhập/giờ',
              '${_statisticsService.formatCurrency(metrics.earningsPerHour)} VNĐ',
              Icons.timer,
            ),
            Divider(height: Dimension.height16),
            _buildMetricRow(
              'Thu nhập/đơn hàng',
              '${_statisticsService.formatCurrency(metrics.earningsPerOrder)} VNĐ',
              Icons.local_shipping,
            ),
            Divider(height: Dimension.height16),
            _buildMetricRow(
              'Tổng khoảng cách',
              _statisticsService.formatDistance(current.totalDistance),
              Icons.route,
            ),
            Divider(height: Dimension.height16),
            _buildMetricRow(
              'Tổng giờ làm việc',
              _statisticsService.formatHours(current.totalHours),
              Icons.work,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColor.primary, size: Dimension.icon20),
        SizedBox(width: Dimension.width8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: Dimension.font_size14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Dimension.font_size14,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPerformanceChart() {
    final dailyData = _statistics!.dailyPerformance;
    
    if (dailyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimension.width20),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: Dimension.icon24 * 2,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: Dimension.height12),
              Text(
                'Chưa có dữ liệu biểu đồ',
                style: TextStyle(
                  fontSize: Dimension.font_size16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu suất theo ngày',
              style: TextStyle(
                fontSize: Dimension.font_size16,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: Dimension.height16),
            ...dailyData.map((data) => _buildDailyPerformanceRow(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPerformanceRow(DailyPerformance data) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimension.height8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _statisticsService.formatDate(data.date),
              style: TextStyle(
                fontSize: Dimension.font_size14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_statisticsService.formatCurrency(data.earnings)} VNĐ',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${data.orders} đơn',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              data.rating > 0 ? data.rating.toStringAsFixed(1) : 'N/A',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAreas() {
    final topAreas = _statistics!.topAreas;
    
    if (topAreas.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimension.width20),
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                size: Dimension.icon24 * 2,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: Dimension.height12),
              Text(
                'Chưa có dữ liệu khu vực',
                style: TextStyle(
                  fontSize: Dimension.font_size16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khu vực giao hàng hàng đầu',
              style: TextStyle(
                fontSize: Dimension.font_size16,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: Dimension.height16),
            ...topAreas.map((area) => _buildTopAreaRow(area)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAreaRow(TopArea area) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimension.height8),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColor.primary,
            size: Dimension.icon20,
          ),
          SizedBox(width: Dimension.width8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.area.replaceAll('"', ''),
                  style: TextStyle(
                    fontSize: Dimension.font_size14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Dimension.height4),
                Row(
                  children: [
                    Text(
                      '${area.orders} đơn hàng',
                      style: TextStyle(
                        fontSize: Dimension.font_size12,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: Dimension.width8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(width: Dimension.width8),
                    Text(
                      '${_statisticsService.formatCurrency(area.revenue)} VNĐ',
                      style: TextStyle(
                        fontSize: Dimension.font_size12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
