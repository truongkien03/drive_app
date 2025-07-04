import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/auth_token.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/driver_fcm_service.dart';
import '../services/driver_location_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Driver? _driver;
  AuthToken? _token;
  bool _isLoading = false;
  String? _error;

  Driver? get driver => _driver;
  AuthToken? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _driver != null && _token != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageService.getToken();
      _driver = await StorageService.getDriver();

      if (_token != null) {
        _apiService.setToken(_token!.accessToken);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendRegisterOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendDriverRegisterOtp(phoneNumber);

      if (response.success) {
        await StorageService.savePhoneNumber(phoneNumber);
        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.registerDriver(phoneNumber, otp);

      if (response.success && response.data != null) {
        _token = response.data;
        _apiService.setToken(_token!.accessToken);

        await StorageService.saveToken(_token!);

        // Get driver profile after registration
        await _loadDriverProfile();

        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendLoginOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendDriverLoginOtp(phoneNumber);

      if (response.success) {
        await StorageService.savePhoneNumber(phoneNumber);
        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.loginDriver(phoneNumber, otp);

      if (response.success && response.data != null) {
        _token = response.data;
        _apiService.setToken(_token!.accessToken);

        await StorageService.saveToken(_token!);

        // Get driver profile after login
        await _loadDriverProfile();

        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithPassword(String phoneNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.loginDriverWithPassword(phoneNumber, password);

      if (response.success && response.data != null) {
        _token = response.data;
        _apiService.setToken(_token!.accessToken);

        await StorageService.saveToken(_token!);

        // Get driver profile after login
        await _loadDriverProfile();

        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setPassword(String password, String passwordConfirmation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Debug token and headers before API call
      _apiService.debugTokenAndHeaders();

      final response =
          await _apiService.setDriverPassword(password, passwordConfirmation);

      if (response.success) {
        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? cmndFrontImagePath, // CMND mặt trước
    String? cmndBackImagePath, // CMND mặt sau
    String? gplxFrontImagePath, // GPLX mặt trước
    String? gplxBackImagePath, // GPLX mặt sau
    String? dangkyXeImagePath, // Đăng ký xe
    String? baohiemImagePath, // Bảo hiểm xe
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 ===== STARTING UPDATE PROFILE =====');

      // Lấy phoneNumber từ driver hiện tại
      final phoneNumber = _driver?.phoneNumber;
      print('📱 Phone number from driver: $phoneNumber');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print('❌ Phone number not found in driver object');
        _error = "Phone number not found";
        return false;
      }

      // Debug token information
      print('🔍 ===== TOKEN DEBUG INFO =====');
      print('🔑 _token object: $_token');
      print('🔑 _token?.accessToken: ${_token?.accessToken}');
      print('🔑 Current ApiService token: ${_apiService.token}');

      // Đảm bảo set token trước khi gọi API
      if (_token?.accessToken != null) {
        _apiService.setToken(_token!.accessToken);
        print(
            '✅ Token set successfully for API request: ${_token!.accessToken}');
        print('🔍 Verify ApiService token after setting: ${_apiService.token}');
      } else {
        print('❌ No access token found in AuthProvider');
        _error = "No access token found";
        return false;
      }

      print('🚀 ===== CALLING API UPDATE PROFILE =====');
      print('📝 Parameters being sent:');
      print('   👤 name: $name');
      print('   📧 email: $email');
      print('   📱 phoneNumber: $phoneNumber');
      print('   📷 cmndFrontImagePath: $cmndFrontImagePath');
      print('   📷 cmndBackImagePath: $cmndBackImagePath');
      print('   🚗 gplxFrontImagePath: $gplxFrontImagePath');
      print('   🚗 gplxBackImagePath: $gplxBackImagePath');
      print('   📄 dangkyXeImagePath: $dangkyXeImagePath');
      print('   🛡️ baohiemImagePath: $baohiemImagePath');

      final response = await _apiService.updateDriverProfile(
        name: name,
        email: email,
        cmndFrontImagePath: cmndFrontImagePath,
        cmndBackImagePath: cmndBackImagePath,
        gplxFrontImagePath: gplxFrontImagePath,
        gplxBackImagePath: gplxBackImagePath,
        dangkyXeImagePath: dangkyXeImagePath,
        baohiemImagePath: baohiemImagePath,
        phoneNumber: phoneNumber, // Truyền phoneNumber để upload lên Firebase
      );

      print('📊 ===== API RESPONSE RECEIVED =====');
      print('✅ Response success: ${response.success}');
      print('📄 Response data: ${response.data}');
      print('❌ Response message: ${response.message}');
      print('🚨 Response errors: ${response.errors}');

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method using direct file upload API
  Future<bool> updateProfileWithFiles({
    String? name,
    String? email,
    String? referenceCode,
    String? cmndFrontImagePath,
    String? cmndBackImagePath,
    String? gplxFrontImagePath,
    String? gplxBackImagePath,
    String? dangkyXeImagePath,
    String? baohiemImagePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 ===== STARTING UPDATE PROFILE WITH FILES =====');

      if (_token?.accessToken == null) {
        print('❌ No access token found');
        _error = "No access token found";
        return false;
      }

      _apiService.setToken(_token!.accessToken);
      print('✅ Token set for API request');

      print('🚀 ===== CALLING NEW API UPDATE PROFILE =====');
      print('📝 Parameters being sent:');
      print('   👤 name: $name');
      print('   📧 email: $email');
      print('   🔗 referenceCode: $referenceCode');
      print('   📷 cmndFrontImagePath: $cmndFrontImagePath');
      print('   📷 cmndBackImagePath: $cmndBackImagePath');
      print('   🚗 gplxFrontImagePath: $gplxFrontImagePath');
      print('   🚗 gplxBackImagePath: $gplxBackImagePath');
      print('   📄 dangkyXeImagePath: $dangkyXeImagePath');
      print('   🛡️ baohiemImagePath: $baohiemImagePath');

      final response = await _apiService.updateDriverProfileWithFiles(
        name: name,
        email: email,
        referenceCode: referenceCode,
        gplxFrontImagePath: gplxFrontImagePath,
        gplxBackImagePath: gplxBackImagePath,
        baohiemImagePath: baohiemImagePath,
        dangkyXeImagePath: dangkyXeImagePath,
        cmndFrontImagePath: cmndFrontImagePath,
        cmndBackImagePath: cmndBackImagePath,
      );

      print('📊 ===== NEW API RESPONSE RECEIVED =====');
      print('✅ Response success: ${response.success}');
      print('📄 Response data: ${response.data}');

      if (response.success && response.data != null) {
        // Update driver info from response
        if (response.data!['data'] != null &&
            response.data!['data']['driver'] != null) {
          _driver = Driver.fromJson(response.data!['data']['driver']);
          await StorageService.saveDriver(_driver!);
          print('✅ Driver profile updated successfully');
        }
        return true;
      } else {
        _error = response.message ?? 'Unknown error occurred';
        print('❌ Profile update failed: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('💥 Profile update error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle driver online status
  Future<bool> toggleOnlineStatus() async {
    if (_driver == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final isCurrentlyOnline = _driver!.status == 1; // 1 = FREE/ONLINE
      final response =
          await _apiService.setDriverOnlineStatus(!isCurrentlyOnline);

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to update status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Set driver status to online
  Future<bool> setDriverOnline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🟢 AuthProvider: Setting driver status to ONLINE...');
      final response = await _apiService.setDriverOnline();

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        print(
            '✅ AuthProvider: Driver status set to ONLINE, new status: ${_driver?.status}');

        // Start location tracking when driver goes online
        await DriverLocationService.startLocationTracking();

        // Force initial location update to ensure current_location is not null
        print('🔧 Ensuring current_location is set...');
        await Future.delayed(Duration(seconds: 2)); // Wait for GPS to be ready
        await DriverLocationService.updateLocationNow();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        print(
            '❌ AuthProvider: Failed to set driver online: ${response.message}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('💥 AuthProvider: Error setting driver online: ${e.toString()}');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Set driver status to offline
  Future<bool> setDriverOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔴 AuthProvider: Setting driver status to OFFLINE...');
      final response = await _apiService.setDriverOffline();

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        print(
            '✅ AuthProvider: Driver status set to OFFLINE, new status: ${_driver?.status}');

        // Stop location tracking when driver goes offline
        DriverLocationService.stopLocationTracking();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        print(
            '❌ AuthProvider: Failed to set driver offline: ${response.message}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('💥 AuthProvider: Error setting driver offline: ${e.toString()}');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to check if driver is online
  bool get isDriverOnline => _driver?.status == 1; // 1 = FREE/ONLINE

  // Simplified method for switch widget
  bool get isOnline => isDriverOnline;

  // Helper method to get status text
  String get driverStatusText {
    switch (_driver?.status) {
      case 1:
        return 'Trực tuyến - Sẵn sàng nhận đơn';
      case 2:
        return 'Ngoại tuyến';
      case 3:
        return 'Bận - Đang giao hàng';
      default:
        return 'Không xác định';
    }
  }

  // Simplified method for status card
  String get statusText => driverStatusText;

  // Helper method to get status color
  Color get statusColor {
    switch (_driver?.status) {
      case 1:
        return Colors.green; // Online/Free
      case 2:
        return Colors.grey; // Offline
      case 3:
        return Colors.orange; // Busy
      default:
        return Colors.red; // Unknown
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword,
      String passwordConfirmation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.changeDriverPassword(
        currentPassword,
        newPassword,
        passwordConfirmation,
      );

      if (response.success) {
        _error = null;
        return true;
      } else {
        _error = _getErrorMessage(response);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      print('🔄 Loading driver profile...');
      final response = await _apiService.getDriverProfile();

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        print('✅ Driver profile loaded successfully');

        // Send FCM token to server after successful login
        await _sendFCMTokenToServer();
      } else {
        print('⚠️ Failed to load driver profile: ${response.message}');
        // Create a minimal driver object if profile loading fails
        _driver = Driver(
          id: 0,
          phoneNumber: await StorageService.getPhoneNumber() ?? '',
          name: 'Tài xế',
          email: '',
          avatar: '',
          status: 1, // active
          hasPassword: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // Profile loading failed, but auth was successful
      print('💥 Failed to load driver profile: $e');
      // Create a minimal driver object if profile loading fails
      _driver = Driver(
        id: 0,
        phoneNumber: await StorageService.getPhoneNumber() ?? '',
        name: 'Tài xế',
        email: '',
        avatar: '',
        status: 1, // active
        hasPassword: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> refreshDriverProfile() async {
    try {
      print('🔄 Refreshing driver profile...');
      final response = await _apiService.getCurrentDriverProfile();

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        print('✅ Driver profile refreshed successfully');
        notifyListeners();
      } else {
        print('❌ Failed to refresh profile: ${response.message}');
      }
    } catch (e) {
      print('💥 Refresh Profile Error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Starting logout process...');

      // Set loading state
      _isLoading = true;
      notifyListeners();

      // Remove FCM token from server before logout (but don't wait too long)
      try {
        await DriverFCMService.removeToken().timeout(Duration(seconds: 5));
        print('✅ FCM token removed successfully');
      } catch (e) {
        print('⚠️ Failed to remove FCM token: $e');
        // Continue with logout even if FCM removal fails
      }

      // Stop location tracking
      DriverLocationService.stopLocationTracking();
      print('✅ Location tracking stopped');

      // Clear all data
      _driver = null;
      _token = null;
      _error = null;

      await StorageService.clearAll();
      _apiService.setToken('');

      _isLoading = false;
      print('✅ Logout completed successfully');

      notifyListeners();
    } catch (e) {
      print('💥 Logout error: $e');

      // Force clear data even if some steps failed
      _driver = null;
      _token = null;
      _error = null;
      _isLoading = false;

      try {
        await StorageService.clearAll();
        _apiService.setToken('');
      } catch (clearError) {
        print('💥 Error clearing storage: $clearError');
      }

      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(response) {
    if (response.message != null) {
      return response.message!;
    }

    if (response.errors != null) {
      final errors = response.errors!;
      final errorMessages = <String>[];

      errors.forEach((key, value) {
        if (value is List) {
          errorMessages.addAll(value.map((e) => e.toString()));
        } else {
          errorMessages.add(value.toString());
        }
      });

      return errorMessages.join(', ');
    }

    return 'Đã xảy ra lỗi. Vui lòng thử lại!';
  }

  Future<void> _sendFCMTokenToServer() async {
    try {
      print('🔔 Sending FCM token to server after login...');
      // Send current FCM token to server
      await DriverFCMService.sendCurrentTokenToServer();
      print('✅ FCM token sent successfully after login');
    } catch (e) {
      print('❌ Error sending FCM token after login: $e');
    }
  }
}
