import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/distance_formatter.dart';

class NewOrderDialog extends StatefulWidget {
  final Order order;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const NewOrderDialog({
    Key? key,
    required this.order,
    this.onAccepted,
    this.onDeclined,
  }) : super(key: key);

  @override
  State<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<NewOrderDialog>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;

  static const int _timeoutSeconds = 15; // 15 giây để tài xế quyết định

  @override
  void initState() {
    super.initState();

    // Tạo animation countdown
    _countdownController = AnimationController(
      duration: Duration(seconds: _timeoutSeconds),
      vsync: this,
    );

    _countdownAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.linear,
    ));

    // Bắt đầu countdown
    _countdownController.forward();

    // Auto decline sau timeout
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _handleDecline('Timeout - Driver did not respond');
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.acceptOrder(widget.order.id);

      if (response.success) {
        // Thành công
        widget.onAccepted?.call();
        Navigator.of(context).pop(true); // Return true để indicate accepted

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã nhận đơn hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi nhận đơn: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleDecline([String? reason]) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.declineOrder(
        widget.order.id,
        reason ?? 'Driver declined',
      );

      if (response.success) {
        widget.onDeclined?.call();
        Navigator.of(context).pop(false); // Return false để indicate declined
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi từ chối đơn: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Không cho phép đóng dialog bằng back button
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header với countdown
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '🚚 Đơn hàng mới!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Countdown timer
                  AnimatedBuilder(
                    animation: _countdownAnimation,
                    builder: (context, child) {
                      final remaining =
                          (_countdownAnimation.value * _timeoutSeconds).ceil();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: remaining <= 5 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${remaining}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Countdown progress bar
              AnimatedBuilder(
                animation: _countdownAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _countdownAnimation.value,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _countdownAnimation.value <= 0.33
                          ? Colors.red
                          : _countdownAnimation.value <= 0.66
                              ? Colors.orange
                              : Colors.green,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Thông tin đơn hàng
              _buildOrderInfo(),

              const SizedBox(height: 24),

              // Action buttons
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleDecline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '❌ Từ chối',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '✅ Nhận đơn',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup location
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: Colors.green,
            title: 'Điểm lấy hàng',
            address: widget.order.fromAddress.desc,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.more_vert,
              color: Colors.grey,
              size: 20,
            ),
          ),

          // Delivery location
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            title: 'Điểm giao hàng',
            address: widget.order.toAddress.desc,
          ),

          const Divider(height: 24),

          // Order details
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  '💰 Phí vận chuyển',
                  CurrencyFormatter.format(widget.order.shippingCost),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  '📏 Khoảng cách',
                  DistanceFormatter.format(widget.order.distance),
                ),
              ),
            ],
          ),

          if (widget.order.userNote?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              '📝 Ghi chú',
              widget.order.userNote!,
            ),
          ],

          if (widget.order.estimatedTime != null) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              '⏱️ Thời gian dự kiến',
              widget.order.estimatedTime!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
