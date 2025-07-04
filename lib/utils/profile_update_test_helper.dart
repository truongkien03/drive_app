import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Helper class to test new profile update API with multipart/form-data
class ProfileUpdateTestHelper {
  /// Test the new profile update API with multipart/form-data
  static Future<void> testProfileUpdateAPI({
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
      print('🧪 ===== TESTING NEW PROFILE UPDATE API =====');

      // Get driver auth token
      final prefs = await SharedPreferences.getInstance();
      String? driverToken = prefs.getString('auth_token');

      if (driverToken == null) {
        print('❌ No driver auth token available for testing');
        return;
      }

      print('🔑 Driver Token: ${driverToken.substring(0, 50)}...');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $driverToken';
      request.headers['Accept'] = 'application/json';

      print(
          '🌐 API Endpoint: ${AppConfig.baseUrl}${AppConfig.driverProfileUpdate}');
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
      await _addTestImageFile(request, 'gplx_front', gplxFrontImagePath);
      await _addTestImageFile(request, 'gplx_back', gplxBackImagePath);
      await _addTestImageFile(request, 'baohiem', baohiemImagePath);
      await _addTestImageFile(request, 'dangky_xe', dangkyXeImagePath);
      await _addTestImageFile(request, 'cmnd_front', cmndFrontImagePath);
      await _addTestImageFile(request, 'cmnd_back', cmndBackImagePath);

      print('📊 Total fields: ${request.fields.length}');
      print('📊 Total files: ${request.files.length}');
      print('📋 Fields: ${request.fields.keys.join(', ')}');
      print('📋 Files: ${request.files.map((f) => f.field).join(', ')}');

      // Make API request
      print('📤 Sending multipart request...');
      final streamedResponse =
          await request.send().timeout(Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ PROFILE UPDATE API: SUCCESS');

        // Parse response according to API spec
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          print('🎉 Server confirmed success: ${responseData['message']}');

          if (responseData['data'] != null) {
            final data = responseData['data'];

            // Driver info
            if (data['driver'] != null) {
              final driver = data['driver'];
              print('👤 Driver updated:');
              print('   📛 Name: ${driver['name']}');
              print('   📧 Email: ${driver['email']}');
              print('   📱 Phone: ${driver['phone_number']}');
              print('   🆔 ID: ${driver['id']}');
              print('   🟢 Status: ${driver['status']}');
            }

            // Profile info
            if (data['profile'] != null) {
              final profile = data['profile'];
              print('📋 Profile updated:');
              print('   🆔 Profile ID: ${profile['id']}');
              print('   🔗 Reference Code: ${profile['reference_code']}');
              print('   ✅ Is Verified: ${profile['is_verified']}');

              // Document URLs
              print('📄 Document URLs:');
              if (profile['gplx_front_url'] != null)
                print('   🚗 GPLX Front: ${profile['gplx_front_url']}');
              if (profile['gplx_back_url'] != null)
                print('   🚗 GPLX Back: ${profile['gplx_back_url']}');
              if (profile['cmnd_front_url'] != null)
                print('   🆔 CMND Front: ${profile['cmnd_front_url']}');
              if (profile['cmnd_back_url'] != null)
                print('   🆔 CMND Back: ${profile['cmnd_back_url']}');
              if (profile['dangky_xe_url'] != null)
                print('   📄 Đăng ký xe: ${profile['dangky_xe_url']}');
              if (profile['baohiem_url'] != null)
                print('   🛡️ Bảo hiểm: ${profile['baohiem_url']}');
            }
          }
        }
      } else if (response.statusCode == 422) {
        print('📋 PROFILE UPDATE API: VALIDATION ERROR');
        final errorData = jsonDecode(response.body);
        print('🚨 Validation Errors:');

        if (errorData['message'] != null) {
          print('   📄 Message: ${errorData['message']}');
        }

        if (errorData['errors'] != null) {
          final errors = errorData['errors'];
          errors.forEach((field, messages) {
            print('   ❌ $field: ${messages.join(', ')}');
          });
        }
      } else if (response.statusCode == 401) {
        print('🔒 PROFILE UPDATE API: UNAUTHORIZED');
        print('❌ Driver token expired or invalid');
      } else {
        print('❌ PROFILE UPDATE API: FAILED');
        print('🚨 Status: ${response.statusCode}');
        print('🚨 Error: ${response.body}');
      }
    } catch (e) {
      print('💥 PROFILE UPDATE API TEST ERROR: $e');
    }
  }

  /// Helper method to add image file to test request
  static Future<void> _addTestImageFile(
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

          final fileSizeKB = (await file.length()) / 1024;
          print(
              '✅ Image added: $fieldName (${fileSizeKB.toStringAsFixed(1)} KB)');
        } else {
          print('❌ Image file not found: $imagePath');
        }
      } catch (e) {
        print('❌ Error adding image $fieldName: $e');
      }
    }
  }

  /// Print API specification for reference
  static void printAPISpecification() {
    print('''
🔥 ===== PROFILE UPDATE API SPECIFICATION =====

📡 UPDATE DRIVER PROFILE
   POST /api/driver/profile
   Headers: 
     Authorization: Bearer {access_token}
     Content-Type: multipart/form-data
   
   📋 Request Body:
   - name: "Nguyễn Văn Tài Xế Mới" (required, max 50 chars)
   - email: "driver@example.com" (optional, valid email, unique)
   - reference_code: "REF12345" (optional)
   - gplx_front: [file] (required, image, max 2MB, jpeg/png/jpg)
   - gplx_back: [file] (required, image, max 2MB, jpeg/png/jpg)
   - baohiem: [file] (required, image, max 2MB, jpeg/png/jpg)
   - dangky_xe: [file] (required, image, max 2MB, jpeg/png/jpg)
   - cmnd_front: [file] (required, image, max 2MB, jpeg/png/jpg)
   - cmnd_back: [file] (required, image, max 2MB, jpeg/png/jpg)

   ✅ Success Response (200):
   {
     "success": true,
     "message": "Profile updated successfully",
     "data": {
       "driver": {
         "id": 1,
         "name": "Nguyễn Văn Tài Xế Mới",
         "phone_number": "+84987654321",
         "email": "driver@example.com",
         "avatar": "http://localhost:8000/storage/avatars/driver_1.jpg",
         "status": "free",
         "current_location": null,
         "created_at": "2024-01-01T00:00:00.000000Z",
         "updated_at": "2024-01-01T00:00:00.000000Z"
       },
       "profile": {
         "id": 1,
         "driver_id": 1,
         "gplx_front_url": "http://localhost:8000/storage/driver_documents/1_gplx_front_1704067200.jpg",
         "gplx_back_url": "http://localhost:8000/storage/driver_documents/1_gplx_back_1704067200.jpg",
         "baohiem_url": "http://localhost:8000/storage/driver_documents/1_baohiem_1704067200.jpg",
         "dangky_xe_url": "http://localhost:8000/storage/driver_documents/1_dangky_xe_1704067200.jpg",
         "cmnd_front_url": "http://localhost:8000/storage/driver_documents/1_cmnd_front_1704067200.jpg",
         "cmnd_back_url": "http://localhost:8000/storage/driver_documents/1_cmnd_back_1704067200.jpg",
         "reference_code": "REF12345",
         "is_verified": false,
         "created_at": "2024-01-01T00:00:00.000000Z",
         "updated_at": "2024-01-01T00:00:00.000000Z"
       }
     }
   }

   ❌ Validation Error (422):
   {
     "message": "The given data was invalid.",
     "errors": {
       "name": ["The name field is required."],
       "gplx_front": ["The gplx front field is required."],
       "email": ["The email has already been taken."]
     }
   }

🎯 BUSINESS LOGIC:
   - Upload và lưu 6 ảnh tài liệu vào local storage
   - Tạo URL public để admin xem và duyệt
   - Tự động xóa ảnh cũ khi upload ảnh mới
   - Admin sẽ verify và cập nhật is_verified = true
   - Tài xế phải có profile verified mới được nhận đơn

⚠️ VALIDATION RULES:
   - name: bắt buộc, tối đa 50 ký tự
   - email: tùy chọn, format email, unique
   - Images: jpeg/png/jpg, max 2MB mỗi file
   - reference_code: tùy chọn

===================================================
    ''');
  }
}
