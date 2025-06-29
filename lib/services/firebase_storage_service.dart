import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage and return URL
  Future<String?> uploadDriverDocument({
    required String filePath,
    required String documentType, // cmnd1, cmnd2, gplx1, gplx2, dkx, bhx
    required String phoneNumber, // Số điện thoại thay vì driverId
  }) async {
    try {
      print('🔥 Uploading to Firebase Storage...');
      print('📁 File path: $filePath');
      print('📋 Document type: $documentType');
      print('� Phone number: $phoneNumber');

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ File does not exist: $filePath');
        return null;
      }

      // Sử dụng cấu trúc Driver/{phone_number}/{fileName}
      final storageRef =
          _storage.ref().child('Driver/$phoneNumber/$documentType');

      print('🚀 Starting upload...');

      // Upload file
      final uploadTask = storageRef.putFile(file);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();
        print('✅ Upload successful!');
        print('🔗 Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('❌ Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      print('💥 Firebase upload error: ${e.toString()}');
      return null;
    }
  }

  // Upload multiple images for a driver
  Future<Map<String, String?>> uploadDriverDocuments({
    required String phoneNumber, // Thay đổi từ driverId thành phoneNumber
    String? cmndFrontPath,
    String? cmndBackPath,
    String? gplxFrontPath,
    String? gplxBackPath,
    String? dangkyXePath,
    String? baohiemPath,
  }) async {
    final results = <String, String?>{};

    try {
      print('🔥 Uploading multiple documents to Firebase...');

      // Upload CMND front (cmnd1)
      if (cmndFrontPath != null && cmndFrontPath.isNotEmpty) {
        results['cmnd_front_url'] = await uploadDriverDocument(
          filePath: cmndFrontPath,
          documentType: 'cmnd1', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      // Upload CMND back (cmnd2)
      if (cmndBackPath != null && cmndBackPath.isNotEmpty) {
        results['cmnd_back_url'] = await uploadDriverDocument(
          filePath: cmndBackPath,
          documentType: 'cmnd2', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      // Upload GPLX front (gplx1)
      if (gplxFrontPath != null && gplxFrontPath.isNotEmpty) {
        results['gplx_front_url'] = await uploadDriverDocument(
          filePath: gplxFrontPath,
          documentType: 'gplx1', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      // Upload GPLX back (gplx2)
      if (gplxBackPath != null && gplxBackPath.isNotEmpty) {
        results['gplx_back_url'] = await uploadDriverDocument(
          filePath: gplxBackPath,
          documentType: 'gplx2', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      // Upload Đăng ký xe (dkx)
      if (dangkyXePath != null && dangkyXePath.isNotEmpty) {
        results['dangky_xe_url'] = await uploadDriverDocument(
          filePath: dangkyXePath,
          documentType: 'dkx', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      // Upload Bảo hiểm (bhx)
      if (baohiemPath != null && baohiemPath.isNotEmpty) {
        results['baohiem_url'] = await uploadDriverDocument(
          filePath: baohiemPath,
          documentType: 'bhx', // Thay đổi tên file theo chuẩn mới
          phoneNumber: phoneNumber,
        );
      }

      print('✅ All uploads completed');
      print('📋 Results: $results');
      return results;
    } catch (e) {
      print('💥 Multiple upload error: ${e.toString()}');
      return results;
    }
  }

  // Delete file from Firebase Storage
  Future<bool> deleteDriverDocument(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      print('🗑️ File deleted successfully: $downloadUrl');
      return true;
    } catch (e) {
      print('💥 Error deleting file: ${e.toString()}');
      return false;
    }
  }
}
