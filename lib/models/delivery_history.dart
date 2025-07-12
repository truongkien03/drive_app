class DeliveryHistoryResponse {
  final PaginationData data;
  final DeliveryStatistics? statistics;

  DeliveryHistoryResponse({
    required this.data,
    this.statistics,
  });

  factory DeliveryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryResponse(
      data: PaginationData.fromJson(json['data']),
      statistics: json['statistics'] != null 
          ? DeliveryStatistics.fromJson(json['statistics']) 
          : null,
    );
  }
}

class PaginationData {
  final int currentPage;
  final List<DeliveryOrder> data;
  final int total;
  final int perPage;
  final String? firstPageUrl;
  final int from;
  final int lastPage;
  final String? lastPageUrl;
  final List<PaginationLink> links;
  final String? nextPageUrl;
  final String path;
  final String? prevPageUrl;
  final int to;

  PaginationData({
    required this.currentPage,
    required this.data,
    required this.total,
    required this.perPage,
    this.firstPageUrl,
    required this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    this.prevPageUrl,
    required this.to,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['current_page'] is String ? int.tryParse(json['current_page']) ?? 1 : (json['current_page'] ?? 1),
      data: (json['data'] as List).map((e) => DeliveryOrder.fromJson(e)).toList(),
      total: json['total'] is String ? int.tryParse(json['total']) ?? 0 : (json['total'] ?? 0),
      perPage: json['per_page'] is String ? int.tryParse(json['per_page']) ?? 15 : (json['per_page'] ?? 15),
      firstPageUrl: json['first_page_url'],
      from: json['from'] is String ? int.tryParse(json['from']) ?? 0 : (json['from'] ?? 0),
      lastPage: json['last_page'] is String ? int.tryParse(json['last_page']) ?? 1 : (json['last_page'] ?? 1),
      lastPageUrl: json['last_page_url'],
      links: (json['links'] as List).map((e) => PaginationLink.fromJson(e)).toList(),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      prevPageUrl: json['prev_page_url'],
      to: json['to'] is String ? int.tryParse(json['to']) ?? 0 : (json['to'] ?? 0),
    );
  }
}

class PaginationLink {
  final String? url;
  final String label;
  final bool active;

  PaginationLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
    );
  }
}

class DeliveryOrder {
  final int id;
  final int userId;
  final int driverId;
  final Address fromAddress;
  final Address toAddress;
  final List<OrderItem> items;
  final double shippingCost;
  final double distance;
  final double discount;
  final int statusCode;
  final String? completedAt;
  final String? driverAcceptAt;
  final String? userNote;
  final String? driverNote;
  final double? driverRate;
  final int isSharable;
  final String? exceptDrivers;
  final String createdAt;
  final String updatedAt;
  final Receiver receiver;
  final String? customerAvatar;
  final String? customerName;
  final Customer customer;
  final Driver driver;
  final List<Tracker> tracker;

  DeliveryOrder({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.items,
    required this.shippingCost,
    required this.distance,
    required this.discount,
    required this.statusCode,
    this.completedAt,
    this.driverAcceptAt,
    this.userNote,
    this.driverNote,
    this.driverRate,
    required this.isSharable,
    this.exceptDrivers,
    required this.createdAt,
    required this.updatedAt,
    required this.receiver,
    this.customerAvatar,
    this.customerName,
    required this.customer,
    required this.driver,
    required this.tracker,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) ?? 0 : (json['user_id'] ?? 0),
      driverId: json['driver_id'] is String ? int.tryParse(json['driver_id']) ?? 0 : (json['driver_id'] ?? 0),
      fromAddress: Address.fromJson(json['from_address']),
      toAddress: Address.fromJson(json['to_address']),
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      shippingCost: json['shipping_cost']?.toDouble() ?? 0.0,
      distance: json['distance']?.toDouble() ?? 0.0,
      discount: json['discount']?.toDouble() ?? 0.0,
      statusCode: json['status_code'] is String ? int.tryParse(json['status_code']) ?? 0 : (json['status_code'] ?? 0),
      completedAt: json['completed_at'],
      driverAcceptAt: json['driver_accept_at'],
      userNote: json['user_note'],
      driverNote: json['driver_note'],
      driverRate: json['driver_rate']?.toDouble(),
      isSharable: json['is_sharable'] is String ? int.tryParse(json['is_sharable']) ?? 0 : (json['is_sharable'] ?? 0),
      exceptDrivers: json['except_drivers'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      receiver: Receiver.fromJson(json['receiver']),
      customerAvatar: json['customerAvatar'],
      customerName: json['customerName'],
      customer: Customer.fromJson(json['customer']),
      driver: Driver.fromJson(json['driver']),
      tracker: (json['tracker'] as List).map((e) => Tracker.fromJson(e)).toList(),
    );
  }
}

class Address {
  final double lat;
  final double lon;
  final String desc;

  Address({
    required this.lat,
    required this.lon,
    required this.desc,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      lat: json['lat']?.toDouble() ?? 0.0,
      lon: json['lon']?.toDouble() ?? 0.0,
      desc: json['desc'] ?? '',
    );
  }
}

class OrderItem {
  final String name;
  final double price;
  final int quantity;
  final String? note;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] is String ? int.tryParse(json['quantity']) ?? 0 : (json['quantity'] ?? 0),
      note: json['note'],
    );
  }
}

class Receiver {
  final String name;
  final String phone;

  Receiver({
    required this.name,
    required this.phone,
  });

  factory Receiver.fromJson(Map<String, dynamic> json) {
    return Receiver(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String avatar;
  final String phoneNumber;
  final Address address;
  final String? emailVerifiedAt;
  final List<String> fcmToken;
  final String createdAt;
  final String updatedAt;
  final bool hasCredential;

  Customer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.phoneNumber,
    required this.address,
    this.emailVerifiedAt,
    required this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    required this.hasCredential,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: Address.fromJson(json['address']),
      emailVerifiedAt: json['email_verified_at'],
      fcmToken: (json['fcm_token'] as List?)?.cast<String>() ?? [],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      hasCredential: json['hasCredential'] ?? false,
    );
  }
}

class Driver {
  final int id;
  final String name;
  final String avatar;
  final String phoneNumber;
  final String email;
  final double? reviewRate;
  final Address currentLocation;
  final int status;
  final int? deliveringOrderId;
  final String fcmToken;
  final String createdAt;
  final String updatedAt;
  final bool hasPassword;

  Driver({
    required this.id,
    required this.name,
    required this.avatar,
    required this.phoneNumber,
    required this.email,
    this.reviewRate,
    required this.currentLocation,
    required this.status,
    this.deliveringOrderId,
    required this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    required this.hasPassword,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      reviewRate: json['review_rate']?.toDouble(),
      currentLocation: Address.fromJson(json['current_location']),
      status: json['status'] is String ? int.tryParse(json['status']) ?? 0 : (json['status'] ?? 0),
      deliveringOrderId: json['delivering_order_id'] is String ? int.tryParse(json['delivering_order_id']) : json['delivering_order_id'],
      fcmToken: json['fcm_token'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      hasPassword: json['hasPassword'] ?? false,
    );
  }
}

class Tracker {
  final int id;
  final int orderId;
  final int status;
  final Map<String, dynamic> description;
  final String note;
  final String createdAt;
  final String updatedAt;

  Tracker({
    required this.id,
    required this.orderId,
    required this.status,
    required this.description,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      orderId: json['order_id'] is String ? int.tryParse(json['order_id']) ?? 0 : (json['order_id'] ?? 0),
      status: json['status'] is String ? int.tryParse(json['status']) ?? 0 : (json['status'] ?? 0),
      description: json['description'] ?? {},
      note: json['note'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class DeliveryStatistics {
  final OverviewStatistics overview;
  final List<DailyStatistics> dailyStats;
  final List<MonthlyStatistics> monthlyStats;

  DeliveryStatistics({
    required this.overview,
    required this.dailyStats,
    required this.monthlyStats,
  });

  factory DeliveryStatistics.fromJson(Map<String, dynamic> json) {
    return DeliveryStatistics(
      overview: OverviewStatistics.fromJson(json['overview']),
      dailyStats: (json['daily_stats'] as List).map((e) => DailyStatistics.fromJson(e)).toList(),
      monthlyStats: (json['monthly_stats'] as List).map((e) => MonthlyStatistics.fromJson(e)).toList(),
    );
  }
}

class OverviewStatistics {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double completionRate;
  final double totalEarnings;
  final double averageRating;
  final double totalDistanceKm;
  final double averageDistancePerOrder;

  OverviewStatistics({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.completionRate,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalDistanceKm,
    required this.averageDistancePerOrder,
  });

  factory OverviewStatistics.fromJson(Map<String, dynamic> json) {
    return OverviewStatistics(
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      completionRate: json['completion_rate']?.toDouble() ?? 0.0,
      totalEarnings: json['total_earnings']?.toDouble() ?? 0.0,
      averageRating: json['average_rating']?.toDouble() ?? 0.0,
      totalDistanceKm: json['total_distance_km']?.toDouble() ?? 0.0,
      averageDistancePerOrder: json['average_distance_per_order']?.toDouble() ?? 0.0,
    );
  }
}

class DailyStatistics {
  final int dayOfWeek;
  final int totalOrders;
  final int completedOrders;
  final double earnings;
  final double avgDistance;

  DailyStatistics({
    required this.dayOfWeek,
    required this.totalOrders,
    required this.completedOrders,
    required this.earnings,
    required this.avgDistance,
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      dayOfWeek: json['day_of_week'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] is String ? int.tryParse(json['completed_orders']) ?? 0 : (json['completed_orders'] ?? 0),
      earnings: json['earnings']?.toDouble() ?? 0.0,
      avgDistance: json['avg_distance']?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyStatistics {
  final int year;
  final int month;
  final int totalOrders;
  final int completedOrders;
  final double earnings;

  MonthlyStatistics({
    required this.year,
    required this.month,
    required this.totalOrders,
    required this.completedOrders,
    required this.earnings,
  });

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] is String ? int.tryParse(json['completed_orders']) ?? 0 : (json['completed_orders'] ?? 0),
      earnings: json['earnings']?.toDouble() ?? 0.0,
    );
  }
} 