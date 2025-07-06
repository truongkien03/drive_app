import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<DriverNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<DriverNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  /// Lấy notifications mới nhất
  List<DriverNotification> get recent => _notifications.take(5).toList();

  /// Lọc notifications theo loại
  List<DriverNotification> getByType(String actionType) {
    return _notifications.where((n) => n.actionType == actionType).toList();
  }

  /// Thêm notification mới
  void addNotification(DriverNotification notification) {
    // Tránh duplicate
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
  }

  /// Cập nhật danh sách notifications
  void updateNotifications(List<DriverNotification> notifications) {
    _notifications = notifications;
    _error = null;
    notifyListeners();
  }

  /// Đánh dấu notification đã đọc
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        readAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    final now = DateTime.now();
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(readAt: now))
        .toList();
    notifyListeners();
  }

  /// Xóa notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Xóa tất cả notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
