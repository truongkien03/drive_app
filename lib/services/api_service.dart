import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/driver.dart';
import '../models/auth_token.dart';
import 'firebase_storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Send OTP for driver registration
  Future<ApiResponse<void>> sendDriverRegisterOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverRegisterOtp}'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData, null);
        } else {
          return ApiResponse.error('Server returned empty response');
        }
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Register driver with OTP
  Future<ApiResponse<AuthToken>> registerDriver(
      String phoneNumber, String otp) async {
    try {
      print(
          '🚀 Sending register request to: ${AppConfig.baseUrl}${AppConfig.driverRegister}');
      print('📱 Phone: $phoneNumber, OTP: $otp');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverRegister}'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
      );

      print('📊 Register Response Status: ${response.statusCode}');
      print('📄 Register Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Register Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Register Success - Token received');
          return ApiResponse.success(AuthToken.fromJson(responseData['data']));
        } else {
          print('❌ Register Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Register Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Register Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Send OTP for driver login
  Future<ApiResponse<void>> sendDriverLoginOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverLoginOtp}'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData, null);
        } else {
          return ApiResponse.error('Server returned empty response');
        }
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Login driver with OTP
  Future<ApiResponse<AuthToken>> loginDriver(
      String phoneNumber, String otp) async {
    try {
      print(
          '🚀 Sending login request to: ${AppConfig.baseUrl}${AppConfig.driverLogin}');
      print('📱 Phone: $phoneNumber, OTP: $otp');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverLogin}'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
      );

      print('📊 Login Response Status: ${response.statusCode}');
      print('📄 Login Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Login Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Login Success - Token received');
          return ApiResponse.success(AuthToken.fromJson(responseData['data']));
        } else {
          print('❌ Login Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Login Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Login Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get driver profile
  Future<ApiResponse<Driver>> getDriverProfile() async {
    try {
      print(
          '🚀 Getting driver profile from: ${AppConfig.baseUrl}${AppConfig.driverProfile}');
      print('🔑 Using token: $_token');

      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfile}'),
            headers: _headers,
          )
          .timeout(Duration(seconds: 10));

      print('📊 Profile Response Status: ${response.statusCode}');
      print('📄 Profile Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Profile Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Profile Success');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Profile Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Profile Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Profile Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Set password for driver
  Future<ApiResponse<void>> setDriverPassword(
      String password, String passwordConfirmation) async {
    try {
      print('🔐 Setting driver password...');
      print('🔑 Request headers: $_headers');
      print('🎯 Current token: $_token');

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}${AppConfig.driverSetPassword}'),
            headers: _headers,
            body: jsonEncode({
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(Duration(seconds: 10));

      print('📊 Set Password Response Status: ${response.statusCode}');
      print('📄 Set Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          print('🔍 Parsed Set Password Response: $responseData');
          print('✅ Password set successfully');
          return ApiResponse.success(null);
        } else {
          print('✅ Password set successfully - Empty response');
          return ApiResponse.success(null);
        }
      } else {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          print('❌ Set Password Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        } else {
          print('❌ Set Password Failed - Empty response');
          return ApiResponse.error('Server returned empty response');
        }
      }
    } catch (e) {
      print('💥 Set Password Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Login driver with password
  Future<ApiResponse<AuthToken>> loginDriverWithPassword(
      String phoneNumber, String password) async {
    try {
      print(
          '🚀 Sending password login request to: ${AppConfig.baseUrl}${AppConfig.driverLoginPassword}');
      print('📱 Phone: $phoneNumber');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverLoginPassword}'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      print('📊 Password Login Response Status: ${response.statusCode}');
      print('📄 Password Login Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Password Login Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Password Login Success - Token received');
          return ApiResponse.success(AuthToken.fromJson(responseData['data']));
        } else {
          print('❌ Password Login Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Password Login Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Password Login Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Update driver profile with Firebase Storage URLs
  Future<ApiResponse<Driver>> updateDriverProfile({
    String? name,
    String? email,
    String? cmndFrontImagePath,
    String? cmndBackImagePath,
    String? gplxFrontImagePath,
    String? gplxBackImagePath,
    String? dangkyXeImagePath,
    String? baohiemImagePath,
    String? cmndFrontUrl,
    String? cmndBackUrl,
    String? gplxFrontUrl,
    String? gplxBackUrl,
    String? dangkyXeUrl,
    String? baohiemUrl,
    String? phoneNumber, // Thay đổi từ driverId thành phoneNumber
  }) async {
    try {
      print('🔄 ===== UPDATING DRIVER PROFILE =====');
      print('🎯 POST ${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}');
      print('🔑 Current ApiService token: $_token');
      print('📱 Phone number: $phoneNumber');
      print('👤 Name: $name');
      print('📧 Email: $email');

      // Check if token exists
      if (_token == null || _token!.isEmpty) {
        print('❌ CRITICAL: No authentication token found in ApiService!');
        print('🔍 Please check if setToken() was called after login/register');
        return ApiResponse.error('No authentication token available');
      }

      final firebaseService = FirebaseStorageService();
      final body = <String, dynamic>{};

      // Add text fields với logging chi tiết
      print('📝 ===== PROCESSING TEXT FIELDS =====');

      if (name != null && name.isNotEmpty) {
        body['name'] = name;
        print('✅ Name added: $name');
      } else {
        print('❌ Name is null or empty: $name');
        // Nếu name null/empty, có thể vẫn muốn gửi để server biết
        if (name != null) {
          body['name'] = name; // Gửi cả string rỗng
          print('⚠️ Sending empty name to server');
        }
      }

      if (email != null && email.isNotEmpty) {
        body['email'] = email; // Đổi lại thành 'email'
        print('✅ Email added with field name email: $email');
      } else {
        print('❌ Email is null or empty: $email');
        // Nếu email null/empty, có thể vẫn muốn gửi để server biết
        if (email != null) {
          body['email'] = email; // Gửi cả string rỗng với field name đúng
          print('⚠️ Sending empty email to server with field name email');
        }
      }

      print(
          '📊 Text fields in body: ${body.entries.where((entry) => entry.key == 'name' || entry.key == 'email').map((entry) => '${entry.key}: ${entry.value}').join(', ')}');

      // Use provided URLs if available, otherwise upload new images
      if (cmndFrontUrl != null && cmndFrontUrl.isNotEmpty) {
        body['cmnd_front_url'] = cmndFrontUrl;
      } else if (cmndFrontImagePath != null &&
          cmndFrontImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('📷 Uploading CMND front image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: cmndFrontImagePath,
          documentType: 'cmnd1', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['cmnd_front_url'] = url;
      }

      if (cmndBackUrl != null && cmndBackUrl.isNotEmpty) {
        body['cmnd_back_url'] = cmndBackUrl;
      } else if (cmndBackImagePath != null &&
          cmndBackImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('📷 Uploading CMND back image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: cmndBackImagePath,
          documentType: 'cmnd2', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['cmnd_back_url'] = url;
      }

      if (gplxFrontUrl != null && gplxFrontUrl.isNotEmpty) {
        body['gplx_front_url'] = gplxFrontUrl;
      } else if (gplxFrontImagePath != null &&
          gplxFrontImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('🚗 Uploading GPLX front image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: gplxFrontImagePath,
          documentType: 'gplx1', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['gplx_front_url'] = url;
      }

      if (gplxBackUrl != null && gplxBackUrl.isNotEmpty) {
        body['gplx_back_url'] = gplxBackUrl;
      } else if (gplxBackImagePath != null &&
          gplxBackImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('🚗 Uploading GPLX back image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: gplxBackImagePath,
          documentType: 'gplx2', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['gplx_back_url'] = url;
      }

      if (dangkyXeUrl != null && dangkyXeUrl.isNotEmpty) {
        body['dangky_xe_url'] = dangkyXeUrl;
      } else if (dangkyXeImagePath != null &&
          dangkyXeImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('📄 Uploading vehicle registration image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: dangkyXeImagePath,
          documentType: 'dkx', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['dangky_xe_url'] = url;
      }

      if (baohiemUrl != null && baohiemUrl.isNotEmpty) {
        body['baohiem_url'] = baohiemUrl;
      } else if (baohiemImagePath != null &&
          baohiemImagePath.isNotEmpty &&
          phoneNumber != null) {
        print('🛡️ Uploading insurance image to Firebase...');
        final url = await firebaseService.uploadDriverDocument(
          filePath: baohiemImagePath,
          documentType: 'bhx', // Cập nhật theo chuẩn mới
          phoneNumber: phoneNumber,
        );
        if (url != null) body['baohiem_url'] = url;
      }

      print('📋 ===== PREPARING REQUEST DATA =====');
      print('📝 Request fields: ${body.keys.join(', ')}');
      print('📊 Total fields count: ${body.length}');

      // Log the actual URLs being sent
      print('🔗 ===== URLS BEING SENT =====');
      if (body['cmnd_front_url'] != null)
        print('   ✅ cmnd_front_url: ${body['cmnd_front_url']}');
      if (body['cmnd_back_url'] != null)
        print('   ✅ cmnd_back_url: ${body['cmnd_back_url']}');
      if (body['gplx_front_url'] != null)
        print('   ✅ gplx_front_url: ${body['gplx_front_url']}');
      if (body['gplx_back_url'] != null)
        print('   ✅ gplx_back_url: ${body['gplx_back_url']}');
      if (body['dangky_xe_url'] != null)
        print('   ✅ dangky_xe_url: ${body['dangky_xe_url']}');
      if (body['baohiem_url'] != null)
        print('   ✅ baohiem_url: ${body['baohiem_url']}');

      if (body.isEmpty) {
        print('❌ WARNING: No data to send to server!');
      }

      // Create multipart request
      print('🚀 ===== CREATING MULTIPART REQUEST =====');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}'),
      );

      // Add headers với logging chi tiết
      print('🔑 ===== SETTING UP HEADERS =====');
      print('🔑 Current token: $_token');
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('✅ Authorization header added: Bearer $_token');
      } else {
        print('❌ No token available for authorization!');
        return ApiResponse.error('No authentication token available');
      }
      request.headers['Accept'] = 'application/json';

      print('📋 Request headers: ${request.headers}');

      // Add fields
      print('📤 ===== ADDING FORM FIELDS =====');
      print('🔍 Body before adding to request: $body');

      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
          print(
              '   ✅ $key: ${value.toString().substring(0, value.toString().length > 50 ? 50 : value.toString().length)}${value.toString().length > 50 ? '...' : ''}');
        } else {
          print('   ❌ Skipping null value for key: $key');
        }
      });

      print('📊 Total fields added: ${request.fields.length}');
      print('📋 All request fields: ${request.fields}');
      print('🔍 Specifically checking name and email:');
      print(
          '   name in request.fields: ${request.fields.containsKey('name') ? request.fields['name'] : 'NOT FOUND'}');
      print(
          '   email in request.fields: ${request.fields.containsKey('email') ? request.fields['email'] : 'NOT FOUND'}');
      print('🌐 Request URL: ${request.url}');
      print('📮 Request method: ${request.method}');

      print('📤 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 ===== SERVER RESPONSE =====');
      print('📊 Update Profile Response Status: ${response.statusCode}');
      print('📄 Update Profile Response Body: ${response.body}');
      print('📋 Response Headers: ${response.headers}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Response Data: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Profile updated successfully with URL strings');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Profile update failed - Status: ${response.statusCode}');
          if (responseData['message'] != null) {
            print('💬 Server message: ${responseData['message']}');
          }
          if (responseData['errors'] != null) {
            print('🚨 Server errors: ${responseData['errors']}');
          }
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Profile update failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Profile Update Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // New method for updating driver profile with direct file upload
  // According to new API spec: POST /api/driver/profile with multipart/form-data
  Future<ApiResponse<Map<String, dynamic>>> updateDriverProfileWithFiles({
    String? name,
    String? email,
    String? referenceCode,
    String? gplxFrontImagePath,
    String? gplxBackImagePath,
    String? baohiemImagePath,
    String? dangkyXeImagePath,
    String? cmndFrontImagePath,
    String? cmndBackImagePath,
  }) async {
    try {
      print('🔄 ===== UPDATING DRIVER PROFILE WITH FILES =====');
      print('🎯 POST ${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}');
      print('🔑 Current token: $_token');

      if (_token == null || _token!.isEmpty) {
        print('❌ No authentication token found!');
        return ApiResponse.error('No authentication token available');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';
      // Note: Don't set Content-Type for multipart, let http package handle it

      print('📋 Request headers: ${request.headers}');

      // Add text fields
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
        print('✅ Name added: $name');
      }

      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
        print('✅ Email added: $email');
      }

      if (referenceCode != null && referenceCode.isNotEmpty) {
        request.fields['reference_code'] = referenceCode;
        print('✅ Reference code added: $referenceCode');
      }

      // Add image files
      await _addImageFile(request, 'gplx_front', gplxFrontImagePath);
      await _addImageFile(request, 'gplx_back', gplxBackImagePath);
      await _addImageFile(request, 'baohiem', baohiemImagePath);
      await _addImageFile(request, 'dangky_xe', dangkyXeImagePath);
      await _addImageFile(request, 'cmnd_front', cmndFrontImagePath);
      await _addImageFile(request, 'cmnd_back', cmndBackImagePath);

      print('📊 Total fields: ${request.fields.length}');
      print('📊 Total files: ${request.files.length}');
      print('📋 Fields: ${request.fields.keys.join(', ')}');
      print('📋 Files: ${request.files.map((f) => f.field).join(', ')}');

      print('📤 Sending multipart request...');
      final streamedResponse =
          await request.send().timeout(Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          print('✅ Profile updated successfully');
          return ApiResponse.success(responseData);
        } else {
          print('❌ Profile update failed');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        return ApiResponse.error('Empty response from server');
      }
    } catch (e) {
      print('💥 Profile Update Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Helper method to add image file to multipart request
  Future<void> _addImageFile(
    http.MultipartRequest request,
    String fieldName,
    String? imagePath,
  ) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            imagePath,
          );
          request.files.add(multipartFile);
          print('✅ Image added: $fieldName (${file.lengthSync()} bytes)');
        } else {
          print('❌ Image file not found: $imagePath');
        }
      } catch (e) {
        print('❌ Error adding image $fieldName: $e');
      }
    }
  }

  // Get current driver profile (for debugging)
  Future<ApiResponse<Driver>> getCurrentDriverProfile() async {
    try {
      print('🔄 Getting current driver profile...');
      print('🎯 GET ${AppConfig.baseUrl}${AppConfig.driverProfile}');
      print('🔑 Using token: $_token');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfile}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30));

      print('📊 Get Profile Response Status: ${response.statusCode}');
      print('📄 Get Profile Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Get Profile Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Profile retrieved successfully');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Profile retrieval failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Profile retrieval failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Get Profile Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Convert image file to Base64 string (backup method)
  Future<String?> imageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      }
      return null;
    } catch (e) {
      print('💥 Error converting image to Base64: ${e.toString()}');
      return null;
    }
  }

  // Debug method to check token and headers
  void debugTokenAndHeaders() {
    print('🔍 Debug Token and Headers:');
    print('🔑 Current token: $_token');
    print('📋 Headers: $_headers');
  }

  // Set driver status to online
  Future<ApiResponse<Driver>> setDriverOnline() async {
    try {
      print('🟢 Setting driver status to ONLINE...');
      print('🎯 POST ${AppConfig.baseUrl}${AppConfig.driverStatusOnline}');
      print('🔑 Using token: $_token');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverStatusOnline}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 10));

      print('📊 Set Online Response Status: ${response.statusCode}');
      print('📄 Set Online Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Set Online Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Driver status set to ONLINE successfully');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Set Online Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Set Online Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Set Online Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Set driver status to offline
  Future<ApiResponse<Driver>> setDriverOffline() async {
    try {
      print('🔴 Setting driver status to OFFLINE...');
      print('🎯 POST ${AppConfig.baseUrl}${AppConfig.driverStatusOffline}');
      print('🔑 Using token: $_token');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverStatusOffline}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 10));

      print('📊 Set Offline Response Status: ${response.statusCode}');
      print('📄 Set Offline Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Set Offline Response: $responseData');

        if (response.statusCode == 200 && responseData['data'] != null) {
          print('✅ Driver status set to OFFLINE successfully');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Set Offline Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        print('❌ Set Offline Failed - Empty response');
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Set Offline Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Change password for driver
  Future<ApiResponse<void>> changeDriverPassword(String currentPassword,
      String newPassword, String passwordConfirmation) async {
    try {
      print('🔐 Changing driver password...');
      print('🔑 Request headers: $_headers');
      print('🎯 Current token: $_token');

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}${AppConfig.driverChangePassword}'),
            headers: _headers,
            body: jsonEncode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(Duration(seconds: 10));

      print('📊 Change Password Response Status: ${response.statusCode}');
      print('📄 Change Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          print('🔍 Parsed Change Password Response: $responseData');
          print('✅ Password changed successfully');
          return ApiResponse.success(null);
        } else {
          print('✅ Password changed successfully - Empty response');
          return ApiResponse.success(null);
        }
      } else {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          print('❌ Change Password Failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        } else {
          print('❌ Change Password Failed - Empty response');
          return ApiResponse.error('Server returned empty response');
        }
      }
    } catch (e) {
      print('💥 Change Password Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Set driver online status
  Future<ApiResponse<Driver>> setDriverOnlineStatus(bool isOnline) async {
    try {
      final endpoint = isOnline
          ? AppConfig.driverStatusOnline
          : AppConfig.driverStatusOffline;

      print('🔄 Setting driver status to ${isOnline ? 'ONLINE' : 'OFFLINE'}');
      print('🎯 POST ${AppConfig.baseUrl}$endpoint');
      print('🔑 Current token: $_token');

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}$endpoint'),
            headers: _headers,
          )
          .timeout(Duration(seconds: 10));

      print('📊 Status Change Response Status: ${response.statusCode}');
      print('📄 Status Change Response Body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        print('🔍 Parsed Status Change Response: $responseData');

        if (responseData['data'] != null) {
          print('✅ Status changed successfully');
          return ApiResponse.success(Driver.fromJson(responseData['data']));
        } else {
          print('❌ Status change failed - No data in response');
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          print('❌ Status change failed - Status: ${response.statusCode}');
          return ApiResponse.fromJson(responseData, null);
        } else {
          print('❌ Status change failed - Empty response');
          return ApiResponse.error('Server returned empty response');
        }
      }
    } catch (e) {
      print('💥 Status Change Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Update driver current location
  Future<ApiResponse<Driver>> updateDriverLocation(
      double lat, double lon) async {
    try {
      print('📍 Updating driver location: $lat, $lon');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverUpdateLocation}'),
        headers: _headers,
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
        }),
      );

      print('📊 Location update response: ${response.statusCode}');
      print('📄 Location update body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(
              responseData, (data) => Driver.fromJson(data));
        } else {
          print('❌ Location update failed - Empty response');
          return ApiResponse.error('Server returned empty response');
        }
      } else if (response.statusCode == 401) {
        print('🔒 Location update failed - Unauthorized');
        return ApiResponse.error('Unauthorized - Please login again');
      } else if (response.statusCode == 422) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData, null);
        } else {
          return ApiResponse.error('Invalid location data');
        }
      } else {
        print('❌ Location update failed - Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData, null);
        } else {
          return ApiResponse.error('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('💥 Location Update Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Order Management APIs

  /// Get order details by ID
  Future<ApiResponse<Map<String, dynamic>>> getOrderDetails(int orderId) async {
    try {
      print('🔍 Getting order details for ID: $orderId');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.orderDetails}/$orderId'),
        headers: _headers,
      );

      print('📊 Order Details Response Status: ${response.statusCode}');
      print('📄 Order Details Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return ApiResponse.success(responseData['data'] ?? responseData);
        } else {
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Get Order Details Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Accept an order
  Future<ApiResponse<Map<String, dynamic>>> acceptOrder(int orderId) async {
    try {
      print('✅ Accepting order ID: $orderId');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.orderAccept}'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      print('📊 Accept Order Response Status: ${response.statusCode}');
      print('📄 Accept Order Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return ApiResponse.success(responseData['data'] ?? responseData);
        } else {
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Accept Order Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Decline an order
  Future<ApiResponse<Map<String, dynamic>>> declineOrder(
      int orderId, String? reason) async {
    try {
      print('❌ Declining order ID: $orderId with reason: $reason');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.orderDecline}'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'reason': reason ?? 'Driver declined',
        }),
      );

      print('📊 Decline Order Response Status: ${response.statusCode}');
      print('📄 Decline Order Response Body: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return ApiResponse.success(responseData['data'] ?? responseData);
        } else {
          return ApiResponse.fromJson(responseData, null);
        }
      } else {
        return ApiResponse.error('Server returned empty response');
      }
    } catch (e) {
      print('💥 Decline Order Error: ${e.toString()}');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}
