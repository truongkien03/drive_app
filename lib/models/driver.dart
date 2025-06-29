class Driver {
  final int? id;
  final String? name;
  final String phoneNumber;
  final String? email;
  final String? avatar;
  final int? status; // 0=Inactive, 1=Active, 2=Banned
  final bool? isOnline; // Trạng thái online/offline
  final bool hasPassword;
  final double? reviewRate;
  final int? totalOrders; // Tổng số đơn hàng
  final int? completedOrders; // Số đơn hoàn thành
  final int? cancelledOrders; // Số đơn bị hủy
  final Location? currentLocation;
  final DriverProfile? profile;
  final VehicleInfo? vehicleInfo; // Thông tin xe
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Driver({
    this.id,
    this.name,
    required this.phoneNumber,
    this.email,
    this.avatar,
    this.status,
    this.isOnline,
    this.hasPassword = false,
    this.reviewRate,
    this.totalOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.currentLocation,
    this.profile,
    this.vehicleInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      name: json['name']?.toString(),
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      status: json['status'] is int
          ? json['status']
          : (json['status'] is String ? int.tryParse(json['status']) : 1),
      isOnline: json['is_online'] is bool ? json['is_online'] : null,
      hasPassword: json['hasPassword'] is bool ? json['hasPassword'] : false,
      reviewRate:
          json['review_rate'] is num ? json['review_rate'].toDouble() : null,
      totalOrders: json['total_orders'] is int ? json['total_orders'] : null,
      completedOrders:
          json['completed_orders'] is int ? json['completed_orders'] : null,
      cancelledOrders:
          json['cancelled_orders'] is int ? json['cancelled_orders'] : null,
      currentLocation: json['current_location'] != null
          ? Location.fromJson(json['current_location'])
          : null,
      profile: json['profile'] != null
          ? DriverProfile.fromJson(json['profile'])
          : null,
      vehicleInfo: json['vehicle_info'] != null
          ? VehicleInfo.fromJson(json['vehicle_info'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'avatar': avatar,
      'status': status,
      'is_online': isOnline,
      'hasPassword': hasPassword,
      'review_rate': reviewRate,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'current_location': currentLocation?.toJson(),
      'profile': profile?.toJson(),
      'vehicle_info': vehicleInfo?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods để hiển thị status
  String get statusText {
    switch (status) {
      case 0:
        return 'Inactive';
      case 1:
        return 'Rảnh';
      case 2:
        return 'Bị cấm';
      default:
        return 'Không xác định';
    }
  }

  bool get isActive => status == 1;
  bool get isBanned => status == 2;
  bool get isInactive => status == 0;
}

class Location {
  final double lat;
  final double lon;
  final String? address;

  Location({
    required this.lat,
    required this.lon,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['latitude'] is num)
          ? json['latitude'].toDouble()
          : (json['lat'] is num)
              ? json['lat'].toDouble()
              : 0.0,
      lon: (json['longitude'] is num)
          ? json['longitude'].toDouble()
          : (json['lon'] is num)
              ? json['lon'].toDouble()
              : 0.0,
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': lat,
      'longitude': lon,
      'address': address,
    };
  }
}

class DriverProfile {
  final int? id;
  final int? driverId;
  final String? gplxFrontUrl;
  final String? gplxBackUrl;
  final String? baohiemUrl;
  final String? dangkyXeUrl;
  final String? cmndFrontUrl;
  final String? cmndBackUrl;
  final String? referenceCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverProfile({
    this.id,
    this.driverId,
    this.gplxFrontUrl,
    this.gplxBackUrl,
    this.baohiemUrl,
    this.dangkyXeUrl,
    this.cmndFrontUrl,
    this.cmndBackUrl,
    this.referenceCode,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      driverId: json['driver_id'] is int
          ? json['driver_id']
          : int.tryParse(json['driver_id']?.toString() ?? '0'),
      gplxFrontUrl: json['gplx_front_url']?.toString(),
      gplxBackUrl: json['gplx_back_url']?.toString(),
      baohiemUrl: json['baohiem_url']?.toString(),
      dangkyXeUrl: json['dangky_xe_url']?.toString(),
      cmndFrontUrl: json['cmnd_front_url']?.toString(),
      cmndBackUrl: json['cmnd_back_url']?.toString(),
      referenceCode: json['reference_code']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'gplx_front_url': gplxFrontUrl,
      'gplx_back_url': gplxBackUrl,
      'baohiem_url': baohiemUrl,
      'dangky_xe_url': dangkyXeUrl,
      'cmnd_front_url': cmndFrontUrl,
      'cmnd_back_url': cmndBackUrl,
      'reference_code': referenceCode,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods để kiểm tra tình trạng tài liệu
  bool get hasCmndFront => cmndFrontUrl != null && cmndFrontUrl!.isNotEmpty;
  bool get hasCmndBack => cmndBackUrl != null && cmndBackUrl!.isNotEmpty;
  bool get hasGplxFront => gplxFrontUrl != null && gplxFrontUrl!.isNotEmpty;
  bool get hasGplxBack => gplxBackUrl != null && gplxBackUrl!.isNotEmpty;
  bool get hasDangkyXe => dangkyXeUrl != null && dangkyXeUrl!.isNotEmpty;
  bool get hasBaohiem => baohiemUrl != null && baohiemUrl!.isNotEmpty;

  bool get hasAllDocuments =>
      hasCmndFront &&
      hasCmndBack &&
      hasGplxFront &&
      hasGplxBack &&
      hasDangkyXe &&
      hasBaohiem;

  // Getter để kiểm tra tình trạng xác minh (tương đương hasAllDocuments)
  bool get isVerified => hasAllDocuments;

  double get completionPercentage {
    int completed = 0;
    if (hasCmndFront) completed++;
    if (hasCmndBack) completed++;
    if (hasGplxFront) completed++;
    if (hasGplxBack) completed++;
    if (hasDangkyXe) completed++;
    if (hasBaohiem) completed++;
    return completed / 6.0;
  }
}

class VehicleInfo {
  final String? type; // motorbike, car, truck, etc.
  final String? brand; // Honda, Yamaha, Toyota, etc.
  final String? model; // SH 150i, Vios, etc.
  final String? licensePlate; // Biển số xe
  final String? color; // Màu xe

  VehicleInfo({
    this.type,
    this.brand,
    this.model,
    this.licensePlate,
    this.color,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      licensePlate: json['license_plate']?.toString(),
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'brand': brand,
      'model': model,
      'license_plate': licensePlate,
      'color': color,
    };
  }

  String get displayName {
    List<String> parts = [];
    if (brand != null && brand!.isNotEmpty) parts.add(brand!);
    if (model != null && model!.isNotEmpty) parts.add(model!);
    if (licensePlate != null && licensePlate!.isNotEmpty) {
      parts.add('(${licensePlate!})');
    }
    return parts.isEmpty ? 'Chưa cập nhật' : parts.join(' ');
  }
}
