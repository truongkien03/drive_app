class AppConfig {
  static const String baseUrl =
      'https://caring-talented-slug.ngrok-free.app/api';

  // Driver API endpoints
  static const String driverRegisterOtp = '/driver/register/otp';
  static const String driverRegister = '/driver/register';
  static const String driverLoginOtp = '/driver/login/otp';
  static const String driverLogin = '/driver/login';
  static const String driverLoginPassword = '/driver/login/password';
  static const String driverProfile = '/driver/profile';
  static const String driverProfileUpdate = '/driver/profile';
  static const String driverSetPassword = '/driver/set-password';
  static const String driverChangePassword = '/driver/change-password';
  static const String driverStatusOnline = '/driver/setting/status/online';
  static const String driverStatusOffline = '/driver/setting/status/offline';
  static const String driverUpdateLocation = '/driver/current-location';

  // FCM endpoints
  static const String driverFCMToken = '/driver/fcm/token';

  // Order endpoints
  static const String orderDetails = '/driver/order'; // GET /driver/order/{id}
  static const String orderAccept =
      '/driver/orders'; // POST /driver/orders/{order}/accept
  static const String orderDecline =
      '/driver/orders'; // POST /driver/orders/{order}/decline
  static const String orderInProcess = '/driver/orders/inprocess'; // GET
  static const String orderCompleted = '/driver/orders/completed'; // GET
  static const String orderCancelled = '/driver/orders/cancelled'; // GET
  static const String orderComplete =
      '/driver/orders'; // POST /driver/orders/{order}/complete
  static const String orderHistory = '/driver/orders/history'; // GET
  static const String driverStatistics = '/driver/statistics'; // GET

  // File upload endpoints
  static const String uploadImage = '/upload/image';

  // App settings
  static const int otpLength = 4;
  static const int otpTimeoutSeconds = 300; // 5 minutes
}
