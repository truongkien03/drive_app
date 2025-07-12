import '../models/delivery_history.dart';
import '../services/api_service.dart';
import '../models/api_response.dart';

class DeliveryHistoryService {
  final ApiService _apiService = ApiService();

  /// Lấy lịch sử giao hàng với các filter
  Future<ApiResponse<DeliveryHistoryResponse>> getDeliveryHistory({
    String? fromDate,
    String? toDate,
    int? status,
    int page = 1,
    int perPage = 15,
    bool includeStats = false,
  }) async {
    return await _apiService.getDeliveryHistory(
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      page: page,
      perPage: perPage,
      includeStats: includeStats,
    );
  }

  /// Lấy chi tiết một đơn hàng cụ thể
  Future<ApiResponse<Map<String, dynamic>>> getDeliveryDetails(int orderId) async {
    return await _apiService.getDeliveryDetails(orderId);
  }

  /// Chuyển đổi status code thành text
  String getStatusText(int statusCode) {
    switch (statusCode) {
      case 1:
        return 'Chờ xử lý';
      case 2:
        return 'Đang xử lý';
      case 3:
        return 'Đã tới địa điểm';
      case 4:
        return 'Đã hoàn thành';
      case 5:
        return 'Bị hủy';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy màu cho status
  String getStatusColor(int statusCode) {
    switch (statusCode) {
      case 1:
        return '#FFA500'; // Orange
      case 2:
        return '#2196F3'; // Blue
      case 3:
        return '#FF9800'; // Orange
      case 4:
        return '#4CAF50'; // Green
      case 5:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Format tiền tệ
  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},'
    )} VNĐ';
  }

  /// Format khoảng cách
  String formatDistance(double distance) {
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Format ngày tháng
  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format thời gian
  String formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format ngày giờ đầy đủ
  String formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  /// Tính thời gian giao hàng
  String calculateDeliveryTime(String? acceptAt, String? completedAt) {
    if (acceptAt == null || completedAt == null) return 'N/A';
    
    try {
      final acceptTime = DateTime.parse(acceptAt);
      final completedTime = DateTime.parse(completedAt);
      final difference = completedTime.difference(acceptTime);
      
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  /// Lấy tên ngày trong tuần
  String getDayOfWeekName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Chủ nhật';
      case 2:
        return 'Thứ 2';
      case 3:
        return 'Thứ 3';
      case 4:
        return 'Thứ 4';
      case 5:
        return 'Thứ 5';
      case 6:
        return 'Thứ 6';
      case 7:
        return 'Thứ 7';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy tên tháng
  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Tháng 1';
      case 2:
        return 'Tháng 2';
      case 3:
        return 'Tháng 3';
      case 4:
        return 'Tháng 4';
      case 5:
        return 'Tháng 5';
      case 6:
        return 'Tháng 6';
      case 7:
        return 'Tháng 7';
      case 8:
        return 'Tháng 8';
      case 9:
        return 'Tháng 9';
      case 10:
        return 'Tháng 10';
      case 11:
        return 'Tháng 11';
      case 12:
        return 'Tháng 12';
      default:
        return 'Không xác định';
    }
  }

  /// Tính tỷ lệ hoàn thành
  double calculateCompletionRate(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  /// Lấy icon cho status
  String getStatusIcon(int statusCode) {
    switch (statusCode) {
      case 1:
        return '⏳';
      case 2:
        return '🚚';
      case 3:
        return '📍';
      case 4:
        return '✅';
      case 5:
        return '❌';
      default:
        return '❓';
    }
  }
} 