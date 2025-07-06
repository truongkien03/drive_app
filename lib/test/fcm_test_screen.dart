import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/driver_fcm_service.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({Key? key}) : super(key: key);

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      await DriverFCMService.initialize();
      setState(() {
        _testResult += '✅ FCM Service initialized\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ FCM init error: $e\n';
      });
    }
  }

  // Simulate new order notification with new format
  Future<void> _testNewOrderNotification() async {
    final testData = {
      "key": "NewOder",
      "link": "driver://AwaitAcceptOder",
      "oderId": "7",
      "type": "new_order_available",
      "screen": "order_list",
      "timestamp": "2025-07-06T01:15:30.123456Z",
      "from_address":
          "{\"lat\":15.982553555413,\"lon\":108.26075384989,\"desc\":\"05, Võ Quí Huân, Đà Nẵng, Việt Nam\"}",
      "to_address":
          "{\"lat\":15.995829503122,\"lon\":108.25824897909,\"desc\":\"03, Đường Mai Đăng Chơn, Đà Nẵng, Việt Nam\"}",
      "distance": "2.1",
      "shipping_cost": "15497",
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "app_type": "driver"
    };

    try {
      setState(() {
        _testResult += '\n📱 Testing new order notification...\n';
        _testResult += 'Data: ${jsonEncode(testData)}\n';
      });

      // Create a mock RemoteMessage to test with
      await _simulateNewOrderNotification(testData);

      setState(() {
        _testResult += '✅ New order notification test completed\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Test error: $e\n';
      });
    }
  }

  // Simulate handling the notification
  Future<void> _simulateNewOrderNotification(Map<String, dynamic> data) async {
    try {
      // Parse order data
      final orderId = data['oderId']?.toString() ?? '';
      final distance = data['distance']?.toString() ?? '';
      final shippingCost = data['shipping_cost']?.toString() ?? '';

      // Parse addresses
      Map<String, dynamic> fromAddress = {};
      Map<String, dynamic> toAddress = {};

      try {
        if (data['from_address'] != null) {
          fromAddress = jsonDecode(data['from_address']);
        }
        if (data['to_address'] != null) {
          toAddress = jsonDecode(data['to_address']);
        }
      } catch (e) {
        setState(() {
          _testResult += '⚠️ Error parsing addresses: $e\n';
        });
      }

      setState(() {
        _testResult += '\n📋 Parsed Order Details:\n';
        _testResult += '   - Order ID: $orderId\n';
        _testResult += '   - Distance: ${distance}km\n';
        _testResult += '   - Shipping Cost: $shippingCost VND\n';
        _testResult += '   - From: ${fromAddress['desc'] ?? 'Unknown'}\n';
        _testResult += '   - To: ${toAddress['desc'] ?? 'Unknown'}\n';
        _testResult +=
            '   - From Coords: ${fromAddress['lat']}, ${fromAddress['lon']}\n';
        _testResult +=
            '   - To Coords: ${toAddress['lat']}, ${toAddress['lon']}\n';
      });

      // Test format helpers
      final formattedCost = _formatCurrency(shippingCost);
      final formattedTime = _formatTimestamp(data['timestamp'] ?? '');

      setState(() {
        _testResult += '\n🎨 Formatted Data:\n';
        _testResult += '   - Cost: $formattedCost VND\n';
        _testResult += '   - Time: $formattedTime\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Simulation error: $e\n';
      });
    }
  }

  // Test notification body generation
  void _testNotificationBody() {
    final testData = {
      "type": "new_order_available",
      "oderId": "7",
      "distance": "2.1",
      "shipping_cost": "15497"
    };

    final body = _generateNotificationBody(testData);

    setState(() {
      _testResult += '\n📝 Generated Notification Body:\n';
      _testResult += '"$body"\n';
    });
  }

  // Test old format compatibility
  void _testOldFormatCompatibility() {
    final oldFormatData = {
      "action_type": "new_order",
      "order_id": "7",
      "distance": "2.1",
      "from_lat": "15.982553555413",
      "from_lon": "108.26075384989",
      "from_desc": "05, Võ Quí Huân, Đà Nẵng, Việt Nam",
      "to_lat": "15.995829503122",
      "to_lon": "108.25824897909",
      "to_desc": "03, Đường Mai Đăng Chơn, Đà Nẵng, Việt Nam",
      "shipping_cost": "15497"
    };

    setState(() {
      _testResult += '\n🔄 Testing old format compatibility...\n';
      _testResult += 'Data: ${jsonEncode(oldFormatData)}\n';
    });

    final body = _generateNotificationBody(oldFormatData);

    setState(() {
      _testResult += 'Generated body: "$body"\n';
      _testResult += '✅ Old format compatibility test completed\n';
    });
  }

  String _generateNotificationBody(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final key = data['key']?.toString() ?? '';
    final actionType = data['action_type']?.toString() ?? '';
    final orderId =
        data['order_id']?.toString() ?? data['oderId']?.toString() ?? '';

    // Handle new format
    if (type == 'new_order_available' || key == 'NewOder') {
      final distance = data['distance']?.toString() ?? '';
      final shippingCost = data['shipping_cost']?.toString() ?? '';
      String bodyText = 'Có đơn hàng mới trong khu vực của bạn.';
      if (distance.isNotEmpty) {
        bodyText += ' Khoảng cách: ${distance}km';
      }
      if (shippingCost.isNotEmpty) {
        try {
          final cost = int.parse(shippingCost);
          final formattedCost = cost.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              );
          bodyText += ' - Phí: ${formattedCost} VND';
        } catch (e) {
          bodyText += ' - Phí: $shippingCost VND';
        }
      }
      return bodyText;
    }

    // Handle old format
    if (actionType == 'new_order') {
      final distance = data['distance']?.toString() ?? '';
      return 'Có đơn hàng mới #$orderId${distance.isNotEmpty ? ' (cách $distance km)' : ''}';
    }

    return 'Bạn có thông báo mới';
  }

  String _formatCurrency(String amount) {
    try {
      final number = int.parse(amount);
      return number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } catch (e) {
      return amount;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _clearLog() {
    setState(() {
      _testResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test Screen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLog,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test buttons
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: _testNewOrderNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test New Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testNotificationBody,
                  icon: const Icon(Icons.message),
                  label: const Text('Test Body Gen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testOldFormatCompatibility,
                  icon: const Icon(Icons.compare),
                  label: const Text('Test Old Format'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Result display
            const Text(
              'Test Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? 'No tests run yet...' : _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
