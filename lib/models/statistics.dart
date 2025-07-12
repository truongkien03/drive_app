class ShipperStatistics {
  final ShipperInfo shipperInfo;
  final Period period;
  final PeriodData currentPeriod;
  final PeriodData previousPeriod;
  final Growth growth;
  final List<DailyPerformance> dailyPerformance;
  final List<TopArea> topAreas;
  final PerformanceMetrics performanceMetrics;

  ShipperStatistics({
    required this.shipperInfo,
    required this.period,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.growth,
    required this.dailyPerformance,
    required this.topAreas,
    required this.performanceMetrics,
  });

  factory ShipperStatistics.fromJson(Map<String, dynamic> json) {
    return ShipperStatistics(
      shipperInfo: ShipperInfo.fromJson(json['shipper_info']),
      period: Period.fromJson(json['period']),
      currentPeriod: PeriodData.fromJson(json['current_period']),
      previousPeriod: PeriodData.fromJson(json['previous_period']),
      growth: Growth.fromJson(json['growth']),
      dailyPerformance: (json['daily_performance'] as List)
          .map((e) => DailyPerformance.fromJson(e))
          .toList(),
      topAreas: (json['top_areas'] as List)
          .map((e) => TopArea.fromJson(e))
          .toList(),
      performanceMetrics: PerformanceMetrics.fromJson(json['performance_metrics']),
    );
  }
}

class ShipperInfo {
  final int id;
  final String name;
  final String phone;
  final String avatar;
  final double? rating;
  final int status;

  ShipperInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    this.rating,
    required this.status,
  });

  factory ShipperInfo.fromJson(Map<String, dynamic> json) {
    return ShipperInfo(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      avatar: json['avatar'],
      rating: json['rating']?.toDouble(),
      status: json['status'],
    );
  }
}

class Period {
  final String type;
  final String startDate;
  final String endDate;

  Period({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      type: json['type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}

class PeriodData {
  final double totalEarnings;
  final double commissionEarned;
  final double commissionRate;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double completionRate;
  final double averageRating;
  final double totalDistance;
  final int totalHours;

  PeriodData({
    required this.totalEarnings,
    required this.commissionEarned,
    required this.commissionRate,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.completionRate,
    required this.averageRating,
    required this.totalDistance,
    required this.totalHours,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      totalEarnings: json['total_earnings']?.toDouble() ?? 0.0,
      commissionEarned: json['commission_earned']?.toDouble() ?? 0.0,
      commissionRate: json['commission_rate']?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      completionRate: json['completion_rate']?.toDouble() ?? 0.0,
      averageRating: json['average_rating']?.toDouble() ?? 0.0,
      totalDistance: json['total_distance']?.toDouble() ?? 0.0,
      totalHours: json['total_hours'] ?? 0,
    );
  }
}

class Growth {
  final double earningsGrowth;
  final double ordersGrowth;
  final double ratingImprovement;

  Growth({
    required this.earningsGrowth,
    required this.ordersGrowth,
    required this.ratingImprovement,
  });

  factory Growth.fromJson(Map<String, dynamic> json) {
    return Growth(
      earningsGrowth: json['earnings_growth']?.toDouble() ?? 0.0,
      ordersGrowth: json['orders_growth']?.toDouble() ?? 0.0,
      ratingImprovement: json['rating_improvement']?.toDouble() ?? 0.0,
    );
  }
}

class DailyPerformance {
  final String date;
  final double earnings;
  final int orders;
  final double rating;
  final double distance;

  DailyPerformance({
    required this.date,
    required this.earnings,
    required this.orders,
    required this.rating,
    required this.distance,
  });

  factory DailyPerformance.fromJson(Map<String, dynamic> json) {
    return DailyPerformance(
      date: json['date'],
      earnings: json['earnings']?.toDouble() ?? 0.0,
      orders: json['orders'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
      distance: json['distance']?.toDouble() ?? 0.0,
    );
  }
}

class TopArea {
  final String area;
  final int orders;
  final double revenue;

  TopArea({
    required this.area,
    required this.orders,
    required this.revenue,
  });

  factory TopArea.fromJson(Map<String, dynamic> json) {
    return TopArea(
      area: json['area'],
      orders: json['orders'] ?? 0,
      revenue: json['revenue']?.toDouble() ?? 0.0,
    );
  }
}

class PerformanceMetrics {
  final double averageOrderValue;
  final double ordersPerDay;
  final double earningsPerHour;
  final double earningsPerOrder;

  PerformanceMetrics({
    required this.averageOrderValue,
    required this.ordersPerDay,
    required this.earningsPerHour,
    required this.earningsPerOrder,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      averageOrderValue: json['average_order_value']?.toDouble() ?? 0.0,
      ordersPerDay: json['orders_per_day']?.toDouble() ?? 0.0,
      earningsPerHour: json['earnings_per_hour']?.toDouble() ?? 0.0,
      earningsPerOrder: json['earnings_per_order']?.toDouble() ?? 0.0,
    );
  }
} 