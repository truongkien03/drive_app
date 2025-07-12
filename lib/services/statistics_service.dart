import '../models/statistics.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final ApiService _apiService = ApiService();

  /// Lấy thống kê shipper theo tháng
  Future<ApiResponse<ShipperStatistics>> getMonthlyStatistics() async {
    return await _apiService.getShipperStatistics(period: 'monthly');
  }

  /// Lấy thống kê shipper theo tuần
  Future<ApiResponse<ShipperStatistics>> getWeeklyStatistics() async {
    return await _apiService.getShipperStatistics(period: 'weekly');
  }

  /// Lấy thống kê shipper theo ngày
  Future<ApiResponse<ShipperStatistics>> getDailyStatistics() async {
    return await _apiService.getShipperStatistics(period: 'daily');
  }

  /// Lấy thống kê shipper theo khoảng thời gian tùy chỉnh
  Future<ApiResponse<ShipperStatistics>> getCustomStatistics({
    required String startDate,
    required String endDate,
    String? period,
  }) async {
    return await _apiService.getShipperStatistics(
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Format số tiền với dấu phẩy
  String formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},'
    );
  }

  /// Format phần trăm
  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Format khoảng cách
  String formatDistance(double distance) {
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Format thời gian
  String formatHours(int hours) {
    return '$hours giờ';
  }

  /// Format ngày tháng
  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Lấy màu cho growth indicator
  int getGrowthColor(double growth) {
    if (growth > 0) return 0xFF4CAF50; // Green
    if (growth < 0) return 0xFFF44336; // Red
    return 0xFF9E9E9E; // Grey
  }

  /// Lấy icon cho growth indicator
  String getGrowthIcon(double growth) {
    if (growth > 0) return '↗️';
    if (growth < 0) return '↘️';
    return '→';
  }

  /// Lấy text cho growth indicator
  String getGrowthText(double growth) {
    if (growth > 0) return '+${growth.toStringAsFixed(1)}%';
    if (growth < 0) return '${growth.toStringAsFixed(1)}%';
    return '0%';
  }

  /// Lấy trạng thái shipper
  String getShipperStatus(int status) {
    switch (status) {
      case 1:
        return 'Online';
      case 2:
        return 'Offline';
      case 3:
        return 'Đang giao hàng';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy màu cho trạng thái shipper
  int getShipperStatusColor(int status) {
    switch (status) {
      case 1:
        return 0xFF4CAF50; // Green
      case 2:
        return 0xFFF44336; // Red
      case 3:
        return 0xFFFF9800; // Orange
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
} 