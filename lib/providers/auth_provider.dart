import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/auth_token.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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

  Future<void> _loadDriverProfile() async {
    try {
      print('🔄 Loading driver profile...');
      final response = await _apiService.getDriverProfile();

      if (response.success && response.data != null) {
        _driver = response.data;
        await StorageService.saveDriver(_driver!);
        print('✅ Driver profile loaded successfully');
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
    _driver = null;
    _token = null;
    _error = null;

    await StorageService.clearAll();
    _apiService.setToken('');

    notifyListeners();
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
}
