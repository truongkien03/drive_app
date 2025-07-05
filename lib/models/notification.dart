class DriverNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  DriverNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['data']?['title']?.toString() ?? '',
      message: json['data']?['message']?.toString() ??
          json['data']?['body']?.toString() ??
          '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': {
        'title': title,
        'message': message,
        ...data,
      },
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRead => readAt != null;

  String get actionType => data['action_type']?.toString() ?? '';
  String get orderId => data['order_id']?.toString() ?? '';
  String get distance => data['distance']?.toString() ?? '';
  String get sharedBy => data['shared_by']?.toString() ?? '';

  // Helper methods để xác định loại notification
  bool get isNewOrder => actionType == 'new_order';
  bool get isOrderCancelled => actionType == 'order_cancelled';
  bool get isOrderShared => actionType == 'order_shared';
  bool get isSystemNotification => actionType.isEmpty;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // Copy with method for updating read status
  DriverNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return DriverNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Enum cho các loại notification actions
enum NotificationActionType {
  newOrder('new_order'),
  orderCancelled('order_cancelled'),
  orderShared('order_shared'),
  system('system');

  const NotificationActionType(this.value);
  final String value;

  static NotificationActionType fromString(String value) {
    switch (value) {
      case 'new_order':
        return NotificationActionType.newOrder;
      case 'order_cancelled':
        return NotificationActionType.orderCancelled;
      case 'order_shared':
        return NotificationActionType.orderShared;
      default:
        return NotificationActionType.system;
    }
  }
}
