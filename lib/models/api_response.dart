class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;
  final int? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: !(json['error'] ?? false),
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message']?.toString(),
      errors: json['errorCode'] is Map
          ? Map<String, dynamic>.from(json['errorCode'])
          : null,
      errorCode: json['errorCode'] is int ? json['errorCode'] : null,
    );
  }

  factory ApiResponse.success(T data) {
    return ApiResponse<T>(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String message,
      {Map<String, dynamic>? errors, int? errorCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      errorCode: errorCode,
    );
  }
}
