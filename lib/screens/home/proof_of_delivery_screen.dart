import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/order.dart';
import '../../utils/app_color.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// Xóa import '../../services/firebase_storage_service.dart';
import 'orders_screen.dart';

class ProofOfDeliveryScreen extends StatefulWidget {
  final Order order;
  final VoidCallback? onOrderCompleted; // Callback để thông báo đơn hàng đã hoàn thành
  const ProofOfDeliveryScreen({Key? key, required this.order, this.onOrderCompleted}) : super(key: key);

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshDriverProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> openMap(double lat, double lon, {BuildContext? context}) async {
    final googleMapsDirUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');

    if (await canLaunchUrl(googleMapsDirUrl)) {
      await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps!')),
        );
      } else {
        print("Không thể mở Google Maps");
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<bool> uploadProofImageToServer(File imageFile, int orderId, {String? note}) async {
    try {
      final url = Uri.parse('https://united-summary-pigeon.ngrok-free.app/api/driver/order-proof-image');
      final request = http.MultipartRequest('POST', url);
      // Thêm token nếu cần
      // request.headers['Authorization'] = 'Bearer <token>';
      request.fields['order_id'] = orderId.toString();
      if (note != null && note.isNotEmpty) {
        request.fields['note'] = note;
      }
      request.files.add(await http.MultipartFile.fromPath('image_url', imageFile.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Có thể parse response.body nếu muốn lấy link ảnh
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _submitProof() async {
    if (_imageFile == null) return;
    setState(() { _isSubmitting = true; });
    String? errorMsg;
    try {
      // Lấy token từ Provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token?.accessToken;
      if (token == null || token.isEmpty) {
        errorMsg = 'Không tìm thấy token đăng nhập!';
      } else {
        final api = ApiService();
        final response = await api.uploadOrderProofImageMultipart(
          orderId: widget.order.id,
          imageFile: _imageFile!,
          note: 'Giao hàng thành công',
          token: token,
        );
        if (response.success) {
          if (mounted) {
            print('✅ Đã xác nhận giao hàng thành công!');
            // Gọi API cập nhật trạng thái shipper về online/free
            final onlineStatusResponse = await api.changeDriverOnlineStatus();
            if (!onlineStatusResponse.success) {
              print('❌ Lỗi cập nhật trạng thái online: ${onlineStatusResponse.message}');
              // Có thể hiển thị thông báo lỗi nếu muốn
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Lỗi cập nhật trạng thái online: ${onlineStatusResponse.message ?? 'Không xác định'}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            _loadDriverProfile();
            
            // Gọi callback nếu có
            widget.onOrderCompleted?.call();
            
            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đã xác nhận giao hàng thành công!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Pop về màn hình trước đó
            Navigator.pop(context);
            
            // Chuyển về OrdersScreen và load lại dữ liệu
            await Future.delayed(Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
              );
            }
          }
        } else {
          errorMsg = response.message ?? 'Lỗi xác nhận đơn hàng!';
          print('❌ Lỗi upload: $errorMsg');
        }
      }
    } catch (e) {
      errorMsg = 'Lỗi: $e';
      print('❌ Exception: $e');
    }
    setState(() { _isSubmitting = false; });
    if (errorMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMsg'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chứng minh giao hàng'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đơn hàng #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColor.primary)),
                    SizedBox(height: 8),
                    Text('Khách: ${order.customer.name}'),
                    if (order.customer.phone != null) Text('SĐT: ${order.customer.phone}'),
                    Text('Địa chỉ: ${order.toAddress.desc}'),
                    Text('Trạng thái: ${order.statusCode}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: _imageFile == null
                  ? Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.primary, width: 2),
                      ),
                      child: Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, width: 220, height: 220, fit: BoxFit.cover),
                    ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: Icon(Icons.camera_alt),
                label: Text('Chụp ảnh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: (_imageFile != null && !_isSubmitting) ? _submitProof : null,
                child: _isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('Xác nhận giao hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Pop về HomeScreen trước
                  Navigator.pop(context);
                  // Đợi pop xong, sau đó mở Google Maps
                  await Future.delayed(Duration(milliseconds: 300));
                  await openMap(order.toAddress.lat, order.toAddress.lon, context: context);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Dẫn đường'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 