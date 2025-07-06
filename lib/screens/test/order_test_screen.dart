import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/order.dart';
import '../../widgets/new_order_dialog.dart';
import '../../services/driver_fcm_service.dart';

class OrderTestScreen extends StatefulWidget {
  const OrderTestScreen({Key? key}) : super(key: key);

  @override
  State<OrderTestScreen> createState() => _OrderTestScreenState();
}

class _OrderTestScreenState extends State<OrderTestScreen> {
  String? _fcmToken;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Get current FCM token
    final token = await DriverFCMService.getToken();
    setState(() {
      _fcmToken = token;
    });

    // Subscribe to driver topics
    await _subscribeToTopics();
  }

  Future<void> _subscribeToTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all-drivers');
      await FirebaseMessaging.instance
          .subscribeToTopic('driver-123'); // Test với driver ID 123

      setState(() {
        _isSubscribed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã đăng ký nhận thông báo từ server'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi đăng ký: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTestOrderDialog() {
    // Tạo đơn hàng test
    final testOrder = Order(
      id: 124,
      fromAddress: OrderAddress(
        lat: 10.7769,
        lon: 106.7009,
        desc: 'Số 1 Nguyễn Huệ, Quận 1, TP.HCM',
      ),
      toAddress: OrderAddress(
        lat: 10.7829,
        lon: 106.6934,
        desc: 'Số 100 Lê Lai, Quận 1, TP.HCM',
      ),
      items: [
        OrderItem(name: 'Áo thun', quantity: 2, weight: '0.5kg'),
        OrderItem(name: 'Quần jeans', quantity: 1, weight: '0.8kg'),
      ],
      shippingCost: 16250,
      distance: 1.25,
      statusCode: 1,
      userNote: 'Gọi điện trước khi giao',
      isSharable: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      user: OrderUser(
        id: 1,
        name: 'Nguyễn Văn A',
        phoneNumber: '+84901234567',
        email: 'user@example.com',
        address: OrderAddress(
          lat: 10.7769,
          lon: 106.7009,
          desc: 'Số 1 Nguyễn Huệ, Quận 1, TP.HCM',
        ),
        avatar: 'https://domain.com/storage/avatars/user.jpg',
      ),
      estimatedTime: '15-20 phút',
      routeInfo: RouteInfo(
        totalDistance: '1.25 km',
        estimatedDuration: '18 phút',
        trafficCondition: 'normal',
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewOrderDialog(
        order: testOrder,
        onAccepted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test: Đã nhận đơn hàng!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onDeclined: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Test: Đã từ chối đơn hàng!'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Nhận Đơn Hàng'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.token, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'FCM Token',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _fcmToken ?? 'Đang lấy token...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _isSubscribed ? Icons.check_circle : Icons.pending,
                          color: _isSubscribed ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSubscribed
                              ? 'Đã đăng ký nhận thông báo'
                              : 'Chưa đăng ký',
                          style: TextStyle(
                            color: _isSubscribed ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Hướng dẫn Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. App đã tự động đăng ký nhận thông báo từ topic "all-drivers"\n'
                      '2. Sử dụng nút "Test Dialog" để xem giao diện nhận đơn\n'
                      '3. Backend có thể gửi FCM notification với format JSON đã mô tả\n'
                      '4. Khi nhận được notification, dialog sẽ tự động hiển thị',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // JSON Format Example
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'JSON Format cho Backend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '{\n'
                        '  "to": "/topics/all-drivers",\n'
                        '  "notification": {\n'
                        '    "title": "Đơn hàng mới",\n'
                        '    "body": "Có đơn hàng mới cần giao"\n'
                        '  },\n'
                        '  "data": {\n'
                        '    "action_type": "new_order",\n'
                        '    "order_id": "124",\n'
                        '    "from_lat": "10.7769",\n'
                        '    "from_lon": "106.7009",\n'
                        '    "from_desc": "Số 1 Nguyễn Huệ, Q1",\n'
                        '    "to_lat": "10.7829",\n'
                        '    "to_lon": "106.6934",\n'
                        '    "to_desc": "Số 100 Lê Lai, Q1",\n'
                        '    "shipping_cost": "16250",\n'
                        '    "distance": "1.25",\n'
                        '    "user_name": "Nguyễn Văn A",\n'
                        '    "user_phone": "+84901234567",\n'
                        '    "user_note": "Gọi điện trước"\n'
                        '  }\n'
                        '}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showTestOrderDialog,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Test Dialog Nhận Đơn',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
