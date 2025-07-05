import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../utils/app_theme.dart';
import '../home/orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      notificationProvider.setError('Vui lòng đăng nhập để xem thông báo');
      return;
    }

    notificationProvider.setLoading(true);

    try {
      final response = await _notificationService.getNotifications();

      if (response.success && response.data != null) {
        notificationProvider.updateNotifications(response.data!);
      } else {
        notificationProvider
            .setError(response.message ?? 'Không thể tải thông báo');
      }
    } catch (e) {
      notificationProvider.setError('Lỗi kết nối: ${e.toString()}');
    }
  }

  List<DriverNotification> _getFilteredNotifications(
      List<DriverNotification> notifications) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'new_order':
        return notifications.where((n) => n.isNewOrder).toList();
      case 'order_shared':
        return notifications.where((n) => n.isOrderShared).toList();
      case 'system':
        return notifications.where((n) => n.isSystemNotification).toList();
      default:
        return notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_all_read':
                        _markAllAsRead();
                        break;
                      case 'clear_all':
                        _clearAllNotifications();
                        break;
                      case 'refresh':
                        _loadNotifications();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read),
                          SizedBox(width: 8),
                          Text('Đánh dấu tất cả đã đọc'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('Xóa tất cả'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Làm mới'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadNotifications,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Tất cả'),
                        const SizedBox(width: 8),
                        _buildFilterChip('unread', 'Chưa đọc'),
                        const SizedBox(width: 8),
                        _buildFilterChip('new_order', 'Đơn hàng mới'),
                        const SizedBox(width: 8),
                        _buildFilterChip('order_shared', 'Chia sẻ'),
                        const SizedBox(width: 8),
                        _buildFilterChip('system', 'Hệ thống'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredNotifications =
                    _getFilteredNotifications(provider.notifications);

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Chưa có thông báo nào'
                              : 'Không có thông báo phù hợp',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;

    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        int count = 0;
        switch (value) {
          case 'unread':
            count = provider.unreadCount;
            break;
          case 'new_order':
            count = provider.getByType('new_order').length;
            break;
          case 'order_shared':
            count = provider.getByType('order_shared').length;
            break;
          case 'system':
            count = provider.getByType('').length;
            break;
          default:
            count = provider.notifications.length;
        }

        return FilterChip(
          label: Text(
            count > 0 ? '$label ($count)' : label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 12,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = value;
            });
          },
          selectedColor: AppTheme.lightTheme.primaryColor,
          backgroundColor: Colors.grey[200],
        );
      },
    );
  }

  Widget _buildNotificationItem(DriverNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _removeNotification(notification.id);
      },
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue[50],
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on notification type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (notification.isNewOrder || notification.isOrderShared)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(DriverNotification notification) {
    if (notification.isNewOrder) {
      return Colors.green;
    } else if (notification.isOrderCancelled) {
      return Colors.red;
    } else if (notification.isOrderShared) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  IconData _getNotificationIcon(DriverNotification notification) {
    if (notification.isNewOrder) {
      return Icons.local_shipping;
    } else if (notification.isOrderCancelled) {
      return Icons.cancel;
    } else if (notification.isOrderShared) {
      return Icons.share;
    } else {
      return Icons.notifications;
    }
  }

  void _onNotificationTap(DriverNotification notification) {
    // Đánh dấu đã đọc
    if (!notification.isRead) {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.markAsRead(notification.id);
      _notificationService.markAsRead(notification.id);
    }

    // Xử lý navigation dựa trên loại notification
    if (notification.isNewOrder || notification.isOrderShared) {
      final orderId = notification.orderId;
      if (orderId.isNotEmpty) {
        // Navigate to order detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrdersScreen(),
          ),
        );
      }
    }
  }

  void _markAllAsRead() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAllAsRead();

    // Update local storage
    for (final notification in provider.notifications) {
      if (!notification.isRead) {
        _notificationService.markAsRead(notification.id);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final provider =
                  Provider.of<NotificationProvider>(context, listen: false);
              provider.clearAll();
              _notificationService.clearAllNotifications();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả thông báo')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _removeNotification(String notificationId) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.removeNotification(notificationId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa thông báo')),
    );
  }
}
