class Order {
  final int id;
  final int userId;
  final int driverId;
  final OrderAddress fromAddress;
  final OrderAddress toAddress;
  final List<OrderItem> items;
  final double shippingCost;
  final double distance;
  final int statusCode;
  final DateTime? driverAcceptAt;
  final DateTime createdAt;
  final Customer customer;

  Order({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.items,
    required this.shippingCost,
    required this.distance,
    required this.statusCode,
    this.driverAcceptAt,
    required this.createdAt,
    required this.customer,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      driverId: json['driver_id'],
      fromAddress: OrderAddress.fromJson(json['from_address']),
      toAddress: OrderAddress.fromJson(json['to_address']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      shippingCost: json['shipping_cost'].toDouble(),
      distance: json['distance'].toDouble(),
      statusCode: json['status_code'],
      driverAcceptAt: json['driver_accept_at'] != null
          ? DateTime.parse(json['driver_accept_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      customer: Customer.fromJson(json['customer']),
    );
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
      lat: json['lat'].toDouble(),
      lon: json['lon'].toDouble(),
      desc: json['desc'],
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? note;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      note: json['note'],
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? avatar;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      avatar: json['avatar'],
    );
  }
}

class OrdersResponse {
  final int currentPage;
  final List<Order> orders;
  final int total;
  final int perPage;

  OrdersResponse({
    required this.currentPage,
    required this.orders,
    required this.total,
    required this.perPage,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      currentPage: json['current_page'],
      orders: (json['data'] as List)
          .map((order) => Order.fromJson(order))
          .toList(),
      total: json['total'],
      perPage: json['per_page'],
    );
  }
}
