import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'driver_service.dart';
import '../models/auth_token.dart';
import '../models/api_response.dart';

/// Service to manage authentication, token storage and user session
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final DriverService _driverService = DriverService();

  static const String _tokenKey = 'accessToken';
  static const String _phoneKey = 'driver_phone_number';
  static const String _userIdKey = 'driver_user_id';

  String? _currentToken;
  String? _currentPhone;
  int? _currentUserId;

  /// Initialize auth service and load saved token
  Future<void> initialize() async {
    try {
      print('🔐 Initializing AuthService...');
      await _loadSavedCredentials();

      if (_currentToken != null) {
        print('✅ Found saved token, setting up services...');
        await _setupServicesWithToken(_currentToken!);
      } else {
        print('ℹ️ No saved token found');
      }
    } catch (e) {
      print('❌ Error initializing AuthService: $e');
    }
  }

  /// Login driver with OTP and save token
  Future<ApiResponse<AuthToken>> loginDriver(
      String phoneNumber, String otp) async {
    try {
      print('🚀 Logging in driver: $phoneNumber');

      final response = await _apiService.loginDriver(phoneNumber, otp);

      if (response.success && response.data != null) {
        print('✅ Login successful, saving credentials...');

        final authToken = response.data!;
        await _saveCredentials(
          token: authToken.accessToken,
          phoneNumber: phoneNumber,
          userId: authToken.token?.userId,
        );

        await _setupServicesWithToken(authToken.accessToken);

        print('🎉 Authentication complete and services initialized');
        return response;
      } else {
        print('❌ Login failed: ${response.message}');
        return response;
      }
    } catch (e) {
      print('💥 Login error: $e');
      return ApiResponse.error('Login error: ${e.toString()}');
    }
  }

  /// Login driver with password and save token
  Future<ApiResponse<AuthToken>> loginDriverWithPassword(
      String phoneNumber, String password) async {
    try {
      print('🚀 Logging in driver with password: $phoneNumber');

      final response =
          await _apiService.loginDriverWithPassword(phoneNumber, password);

      if (response.success && response.data != null) {
        print('✅ Password login successful, saving credentials...');

        final authToken = response.data!;
        await _saveCredentials(
          token: authToken.accessToken,
          phoneNumber: phoneNumber,
          userId: authToken.token?.userId,
        );

        await _setupServicesWithToken(authToken.accessToken);

        print('🎉 Authentication complete and services initialized');
        return response;
      } else {
        print('❌ Password login failed: ${response.message}');
        return response;
      }
    } catch (e) {
      print('💥 Password login error: $e');
      return ApiResponse.error('Password login error: ${e.toString()}');
    }
  }

  /// Logout and clear all saved data
  Future<void> logout() async {
    try {
      print('🚪 Logging out driver...');

      // Stop location tracking
      _locationService.stopLocationTracking();

      // Go offline
      await _driverService.goOffline();

      // Clear saved credentials
      await _clearSavedCredentials();

      // Clear API service token
      _apiService.clearToken();

      // Reset location service auth status
      _locationService.resetAuthenticationStatus();

      print('✅ Logout complete');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentToken != null;

  /// Get current token
  String? get currentToken => _currentToken;

  /// Get current phone number
  String? get currentPhone => _currentPhone;

  /// Get current user ID
  int? get currentUserId => _currentUserId;

  /// Debug method to check token state
  void debugTokenState() {
    print('🔍 ===== AUTH SERVICE DEBUG =====');
    print(
        '🔑 Current Token: ${_currentToken != null ? "${_currentToken!.substring(0, 20)}..." : "NULL"}');
    print('📱 Current Phone: $_currentPhone');
    print('👤 Current User ID: $_currentUserId');
    print('✅ Is Authenticated: $isAuthenticated');
    print('🔍 ===============================');

    // Also debug ApiService
    _apiService.debugTokenAndHeaders();
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials({
    required String token,
    required String phoneNumber,
    int? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_tokenKey, token);
      await prefs.setString(_phoneKey, phoneNumber);

      if (userId != null) {
        await prefs.setInt(_userIdKey, userId);
      }

      _currentToken = token;
      _currentPhone = phoneNumber;
      _currentUserId = userId;

      print('💾 Credentials saved successfully');
    } catch (e) {
      print('❌ Error saving credentials: $e');
    }
  }

  /// Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentToken = prefs.getString(_tokenKey);
      _currentPhone = prefs.getString(_phoneKey);
      _currentUserId = prefs.getInt(_userIdKey);

      if (_currentToken != null) {
        print('✅ Loaded saved credentials for: $_currentPhone');
      }
    } catch (e) {
      print('❌ Error loading saved credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_userIdKey);

      _currentToken = null;
      _currentPhone = null;
      _currentUserId = null;

      print('🗑️ Saved credentials cleared');
    } catch (e) {
      print('❌ Error clearing saved credentials: $e');
    }
  }

  /// Setup all services with the authenticated token
  Future<void> _setupServicesWithToken(String token) async {
    try {
      print('⚙️ Setting up services with token...');

      // Set token in API service
      _apiService.setToken(token);

      // Set token in driver service
      _driverService.setDriverToken(token);

      // Reset location service auth status
      _locationService.resetAuthenticationStatus();

      print('✅ All services configured with authentication token');
    } catch (e) {
      print('❌ Error setting up services: $e');
    }
  }

  /// Refresh token if needed (for future implementation)
  Future<bool> refreshTokenIfNeeded() async {
    // TODO: Implement token refresh logic if backend supports it
    return isAuthenticated;
  }

  /// Handle authentication error (when token is invalid)
  Future<void> handleAuthenticationError() async {
    print('🔒 Handling authentication error...');

    // Clear invalid token
    await _clearSavedCredentials();
    _apiService.clearToken();

    // Reset location service
    _locationService.resetAuthenticationStatus();

    print('⚠️ Authentication error handled - user needs to login again');
  }
}
