import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class OrderApiTestScreen extends StatefulWidget {
  const OrderApiTestScreen({Key? key}) : super(key: key);

  @override
  State<OrderApiTestScreen> createState() => _OrderApiTestScreenState();
}

class _OrderApiTestScreenState extends State<OrderApiTestScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  String _testResult = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token != null) {
        _apiService.setToken(token);
        setState(() {
          _testResult += '✅ Token loaded: ${token.substring(0, 50)}...\n';
        });
      } else {
        setState(() {
          _testResult += '❌ No token found in SharedPreferences\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResult += '❌ Error loading token: $e\n';
      });
    }
  }

  Future<void> _testAcceptOrder() async {
    final orderIdText = _orderIdController.text.trim();
    if (orderIdText.isEmpty) {
      setState(() {
        _testResult += '⚠️ Please enter order ID\n';
      });
      return;
    }

    final orderId = int.tryParse(orderIdText);
    if (orderId == null) {
      setState(() {
        _testResult += '❌ Invalid order ID format\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult += '\n🚀 Testing Accept Order API...\n';
      _testResult += 'Order ID: $orderId\n';
    });

    try {
      // Test API call
      final response = await _apiService.acceptOrder(orderId);

      setState(() {
        _testResult += '\n📊 API Response:\n';
        _testResult += 'Success: ${response.success}\n';
        _testResult += 'Message: ${response.message}\n';
        _testResult += 'Data: ${response.data}\n';

        if (response.success) {
          _testResult += '🎉 Order accepted successfully!\n';
        } else {
          _testResult += '❌ Failed to accept order\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '💥 Exception occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDeclineOrder() async {
    final orderIdText = _orderIdController.text.trim();
    if (orderIdText.isEmpty) {
      setState(() {
        _testResult += '⚠️ Please enter order ID\n';
      });
      return;
    }

    final orderId = int.tryParse(orderIdText);
    if (orderId == null) {
      setState(() {
        _testResult += '❌ Invalid order ID format\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult += '\n🚀 Testing Decline Order API...\n';
      _testResult += 'Order ID: $orderId\n';
    });

    try {
      final response =
          await _apiService.declineOrder(orderId, 'Test decline from app');

      setState(() {
        _testResult += '\n📊 API Response:\n';
        _testResult += 'Success: ${response.success}\n';
        _testResult += 'Message: ${response.message}\n';
        _testResult += 'Data: ${response.data}\n';

        if (response.success) {
          _testResult += '✅ Order declined successfully!\n';
        } else {
          _testResult += '❌ Failed to decline order\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '💥 Exception occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetOrderDetails() async {
    final orderIdText = _orderIdController.text.trim();
    if (orderIdText.isEmpty) {
      setState(() {
        _testResult += '⚠️ Please enter order ID\n';
      });
      return;
    }

    final orderId = int.tryParse(orderIdText);
    if (orderId == null) {
      setState(() {
        _testResult += '❌ Invalid order ID format\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult += '\n🚀 Testing Get Order Details API...\n';
      _testResult += 'Order ID: $orderId\n';
    });

    try {
      final response = await _apiService.getOrderDetails(orderId);

      setState(() {
        _testResult += '\n📊 API Response:\n';
        _testResult += 'Success: ${response.success}\n';
        _testResult += 'Message: ${response.message}\n';
        _testResult += 'Data: ${response.data}\n';

        if (response.success) {
          _testResult += '📋 Order details retrieved successfully!\n';
        } else {
          _testResult += '❌ Failed to get order details\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '💥 Exception occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetInProcessOrders() async {
    setState(() {
      _isLoading = true;
      _testResult += '\n🚀 Testing Get In-Process Orders API...\n';
    });

    try {
      final response = await _apiService.getInProcessOrders();

      setState(() {
        _testResult += '\n📊 API Response:\n';
        _testResult += 'Success: ${response.success}\n';
        _testResult += 'Message: ${response.message}\n';
        _testResult += 'Data Count: ${response.data?.length ?? 0}\n';

        if (response.success) {
          _testResult += '📋 In-process orders retrieved successfully!\n';
          if (response.data?.isNotEmpty == true) {
            _testResult += 'Sample order: ${response.data![0]}\n';
          }
        } else {
          _testResult += '❌ Failed to get in-process orders\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '💥 Exception occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Order API Test'),
        backgroundColor: Colors.orange,
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
            // Order ID Input
            TextField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                border: OutlineInputBorder(),
                hintText: 'Enter order ID (e.g., 7)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Test buttons
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testAcceptOrder,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testDeclineOrder,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetOrderDetails,
                  icon: const Icon(Icons.info),
                  label: const Text('Get Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetInProcessOrders,
                  icon: const Icon(Icons.list),
                  label: const Text('Get In-Process'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Testing API...'),
                  ],
                ),
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

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }
}
