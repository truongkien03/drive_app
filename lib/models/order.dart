import 'dart:convert';

class Order {
  final int id;
  final int? userId;
  final int? driverId;
  final OrderAddress fromAddress;
  final OrderAddress toAddress;
  final List<OrderItem> items;
  final double shippingCost;
  final double distance;
  final int statusCode;
  final String? userNote;
  final String? driverNote;
  final bool isSharable;
  final List<int>? exceptDrivers;
  final DateTime? completedAt;
  final DateTime? driverAcceptAt;
  final double? driverRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderUser? user;
  final OrderDriver? driver;
  final String? estimatedTime;
  final RouteInfo? routeInfo;

  Order({
    required this.id,
    this.userId,
    this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.items,
    required this.shippingCost,
    required this.distance,
    required this.statusCode,
    this.userNote,
    this.driverNote,
    required this.isSharable,
    this.exceptDrivers,
    this.completedAt,
    this.driverAcceptAt,
    this.driverRate,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.driver,
    this.estimatedTime,
    this.routeInfo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
      driverId: json['driver_id'] is int
          ? json['driver_id']
          : int.tryParse(json['driver_id']?.toString() ?? ''),
      fromAddress: OrderAddress.fromJson(json['from_address'] ?? {}),
      toAddress: OrderAddress.fromJson(json['to_address'] ?? {}),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
      shippingCost: (json['shipping_cost'] is num)
          ? json['shipping_cost'].toDouble()
          : 0.0,
      distance: (json['distance'] is num) ? json['distance'].toDouble() : 0.0,
      statusCode: json['status_code'] is int ? json['status_code'] : 1,
      userNote: json['user_note']?.toString(),
      driverNote: json['driver_note']?.toString(),
      isSharable: json['is_sharable'] is bool ? json['is_sharable'] : false,
      exceptDrivers: json['except_drivers'] != null
          ? List<int>.from(json['except_drivers']
              .map((x) => int.tryParse(x.toString()) ?? 0))
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      driverAcceptAt: json['driver_accept_at'] != null
          ? DateTime.tryParse(json['driver_accept_at'].toString())
          : null,
      driverRate:
          json['driver_rate'] is num ? json['driver_rate'].toDouble() : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      user: json['user'] != null ? OrderUser.fromJson(json['user']) : null,
      driver:
          json['driver'] != null ? OrderDriver.fromJson(json['driver']) : null,
      estimatedTime: json['estimated_time']?.toString(),
      routeInfo: json['route_info'] != null
          ? RouteInfo.fromJson(json['route_info'])
          : null,
    );
  }

  // Create Order from FCM notification data
  factory Order.fromFCMData(Map<String, dynamic> data) {
    // Parse addresses from new format (they come as JSON strings)
    Map<String, dynamic> fromAddress = {};
    Map<String, dynamic> toAddress = {};

    try {
      if (data['from_address'] != null) {
        fromAddress = json.decode(data['from_address']);
      }
      if (data['to_address'] != null) {
        toAddress = json.decode(data['to_address']);
      }
    } catch (e) {
      print('Error parsing address data: $e');
    }

    // Try to get order ID from new format first, then old format
    final orderIdStr =
        data['oderId']?.toString() ?? data['order_id']?.toString() ?? '0';
    final orderId = int.tryParse(orderIdStr) ?? 0;

    return Order(
      id: orderId,
      fromAddress: OrderAddress(
        // New format
        lat: double.tryParse(fromAddress['lat']?.toString() ?? '0') ??
            // Old format fallback
            double.tryParse(data['from_lat']?.toString() ?? '0') ??
            0.0,
        lon: double.tryParse(fromAddress['lon']?.toString() ?? '0') ??
            double.tryParse(data['from_lon']?.toString() ?? '0') ??
            0.0,
        desc: fromAddress['desc']?.toString() ??
            data['from_desc']?.toString() ??
            '',
      ),
      toAddress: OrderAddress(
        // New format
        lat: double.tryParse(toAddress['lat']?.toString() ?? '0') ??
            // Old format fallback
            double.tryParse(data['to_lat']?.toString() ?? '0') ??
            0.0,
        lon: double.tryParse(toAddress['lon']?.toString() ?? '0') ??
            double.tryParse(data['to_lon']?.toString() ?? '0') ??
            0.0,
        desc:
            toAddress['desc']?.toString() ?? data['to_desc']?.toString() ?? '',
      ),
      items: _parseItemsFromString(data['items']?.toString()),
      shippingCost:
          double.tryParse(data['shipping_cost']?.toString() ?? '0') ?? 0.0,
      distance: double.tryParse(data['distance']?.toString() ?? '0') ?? 0.0,
      statusCode: 1, // New order
      userNote: data['user_note']?.toString(),
      isSharable: false,
      createdAt: data['created_at'] != null || data['timestamp'] != null
          ? DateTime.tryParse(data['created_at']?.toString() ??
                  data['timestamp']?.toString() ??
                  '') ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: DateTime.now(),
      user: OrderUser(
        id: 0,
        name: data['user_name']?.toString() ?? '',
        phoneNumber: data['user_phone']?.toString() ?? '',
        email: '',
        address: null,
        avatar: null,
      ),
    );
  }

  static List<OrderItem> _parseItemsFromString(String? itemsStr) {
    if (itemsStr == null || itemsStr.isEmpty) return [];

    try {
      final List<dynamic> itemsJson = json.decode(itemsStr);
      return itemsJson.map((item) => OrderItem.fromJson(item)).toList();
    } catch (e) {
      print('Error parsing items: $e');
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'from_address': fromAddress.toJson(),
      'to_address': toAddress.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_cost': shippingCost,
      'distance': distance,
      'status_code': statusCode,
      'user_note': userNote,
      'driver_note': driverNote,
      'is_sharable': isSharable,
      'except_drivers': exceptDrivers,
      'completed_at': completedAt?.toIso8601String(),
      'driver_accept_at': driverAcceptAt?.toIso8601String(),
      'driver_rate': driverRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'driver': driver?.toJson(),
      'estimated_time': estimatedTime,
      'route_info': routeInfo?.toJson(),
    };
  }

  // Status helper methods
  bool get isPending => statusCode == 1;
  bool get isInProcess => statusCode == 2;
  bool get isCompleted => statusCode == 3;
  bool get isCancelledByDriver => statusCode == 4;
  bool get isCancelledByUser => statusCode == 5;

  String get statusText {
    switch (statusCode) {
      case 1:
        return 'Chờ tài xế nhận';
      case 2:
        return 'Đang thực hiện';
      case 3:
        return 'Hoàn thành';
      case 4:
        return 'Tài xế hủy';
      case 5:
        return 'Khách hàng hủy';
      default:
        return 'Không xác định';
    }
  }

  // Convenience getters for UI
  String get customerName => user?.name ?? 'Không có tên';
  String get customerPhone => user?.phoneNumber ?? '';
  String get pickupAddress => fromAddress.desc;
  String get dropoffAddress => toAddress.desc;
  double get fare => shippingCost;

  String get formattedShippingCost {
    return '${shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} đ';
  }

  String get formattedDistance {
    return '${distance.toStringAsFixed(2)} km';
  }
}

class OrderAddress {
  final double lat;
  final double lon;
  final String desc;

  OrderAddress({
    required this.lat,
    required this.lon,
    required this.desc,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      lat: (json['lat'] is num) ? json['lat'].toDouble() : 0.0,
      lon: (json['lon'] is num) ? json['lon'].toDouble() : 0.0,
      desc: json['desc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'desc': desc,
    };
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final String? weight;

  OrderItem({
    required this.name,
    required this.quantity,
    this.weight,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      weight: json['weight']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'weight': weight,
    };
  }
}

class OrderUser {
  final int id;
  final String name;
  final String phoneNumber;
  final String email;
  final OrderAddress? address;
  final String? avatar;

  OrderUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.address,
    this.avatar,
  });

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address'] != null
          ? OrderAddress.fromJson(json['address'])
          : null,
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'address': address?.toJson(),
      'avatar': avatar,
    };
  }
}

class OrderDriver {
  final int id;
  final String name;
  final String phoneNumber;
  final String? avatar;

  OrderDriver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.avatar,
  });

  factory OrderDriver.fromJson(Map<String, dynamic> json) {
    return OrderDriver(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'avatar': avatar,
    };
  }
}

class RouteInfo {
  final String totalDistance;
  final String estimatedDuration;
  final String trafficCondition;

  RouteInfo({
    required this.totalDistance,
    required this.estimatedDuration,
    required this.trafficCondition,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      totalDistance: json['total_distance']?.toString() ?? '',
      estimatedDuration: json['estimated_duration']?.toString() ?? '',
      trafficCondition: json['traffic_condition']?.toString() ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_distance': totalDistance,
      'estimated_duration': estimatedDuration,
      'traffic_condition': trafficCondition,
    };
  }
}
