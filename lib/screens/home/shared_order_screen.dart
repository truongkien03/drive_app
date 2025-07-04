import 'package:flutter/material.dart';

class SharedOrderScreen extends StatefulWidget {
  final String orderId;

  const SharedOrderScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<SharedOrderScreen> createState() => _SharedOrderScreenState();
}

class _SharedOrderScreenState extends State<SharedOrderScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng chia sẻ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shared Order Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Đơn hàng được chia sẻ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bạn được mời tham gia giao đơn hàng này cùng với tài xế khác.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Order Details Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Mã đơn hàng: ${widget.orderId}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Khách hàng', 'Trần Thị B'),
                    _buildInfoRow('Điện thoại', '0901234567'),
                    _buildInfoRow(
                        'Địa chỉ lấy hàng', '789 Võ Văn Tần, Q3, TP.HCM'),
                    _buildInfoRow(
                        'Địa chỉ giao hàng', '321 Hai Bà Trưng, Q1, TP.HCM'),
                    _buildInfoRow('Khoảng cách', '3.8 km'),
                    _buildInfoRow('Phí giao hàng chia sẻ', '25,000đ'),
                    _buildInfoRow('Tài xế chính', 'Nguyễn Văn C'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Benefits Card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Lợi ích khi tham gia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Tăng thu nhập từ đơn hàng chia sẻ'),
                    Text('• Tối ưu hóa tuyến đường giao hàng'),
                    Text('• Giảm thời gian chờ đơn hàng mới'),
                  ],
                ),
              ),
            ),

            Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _declineSharedOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Từ chối'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptSharedOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Tham gia'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptSharedOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call API to accept shared order
      await Future.delayed(Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia đơn hàng chia sẻ #${widget.orderId}'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể tham gia đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineSharedOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call API to decline shared order
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối đơn hàng chia sẻ #${widget.orderId}'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể từ chối đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
