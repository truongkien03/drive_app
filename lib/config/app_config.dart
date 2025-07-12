class AppConfig {
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String baseUrl = 'https://united-summary-pigeon.ngrok-free.app/api';
  // TODO: Cập nhật URL khi ngrok tunnel thay đổi
  // static const String baseUrl = 'https://your-new-ngrok-url.ngrok-free.app/api';
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
  static const String driverOrders = '/driver/orders/my-orders';
  static const String driverOrderArrived = '/driver/orders';
  static const String driverOrdersActive = '/driver/drive/order-pending/active-list';
  static const String driverOrdersArriving = '/driver/drive/order-pending/arriving-list';
  static const String driverOrdersCompleted = '/driver/drive/order-pending/completed-list';
  static const String driverOrdersCancelled = '/driver/drive/order-pending/cancelled-list';

  // Statistics endpoints
  static const String driverStatistics = '/driver/statistics/shipper';

  // Delivery history endpoints
  static const String driverDeliveryHistory = '/driver/orders/delivery-history';
  static const String driverDeliveryDetails = '/driver/orders';

  // FCM endpoints
  static const String driverFCMToken = '/driver/fcm/token';

  // File upload endpoints
  static const String uploadImage = '/upload/image';

  // App settings
  static const int otpLength = 4;
  static const int otpTimeoutSeconds = 300; // 5 minutes
}
