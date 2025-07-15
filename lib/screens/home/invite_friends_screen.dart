import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({Key? key}) : super(key: key);

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final String _referralCode = 'DRIVER2024';
  final List<Map<String, dynamic>> _invitedFriends = [
    {
      'name': 'Nguyễn Văn A',
      'phone': '0901234567',
      'status': 'Đã đăng ký',
      'date': '15/12/2024',
    },
    {
      'name': 'Trần Thị B',
      'phone': '0907654321',
      'status': 'Chờ xác nhận',
      'date': '14/12/2024',
    },
    {
      'name': 'Lê Văn C',
      'phone': '0912345678',
      'status': 'Đã đăng ký',
      'date': '13/12/2024',
    },
  ];

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã sao chép mã giới thiệu: $_referralCode'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareReferralCode() {
    // TODO: Implement social media sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📤 Chia sẻ mã giới thiệu qua mạng xã hội'),
        backgroundColor: AppColor.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã đăng ký':
        return Colors.green;
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Mời bạn bè',
          style: TextStyle(
            fontSize: Dimension.font_size18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: EdgeInsets.all(Dimension.width20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Row(
                  children: [
                  Container(
                    padding: EdgeInsets.all(Dimension.width12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(Dimension.radius12),
                    ),
                    child: Icon(
                      Icons.people,
                      color: Colors.white,
                      size: Dimension.icon24,
                    ),
                    ),
                  SizedBox(width: Dimension.width16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                      'Mời bạn bè trở thành tài xế',
                      style: TextStyle(
                            color: Colors.white,
                            fontSize: Dimension.font_size18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                        SizedBox(height: Dimension.height8),
                    Text(
                      'Chia sẻ mã giới thiệu để bạn bè có thể tham gia và nhận thưởng hấp dẫn!',
                      style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: Dimension.font_size14,
                      ),
                    ),
                  ],
                ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: Dimension.height20),
            
            // Referral code section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: AppColor.primary,
                          size: Dimension.icon20,
                        ),
                        SizedBox(width: Dimension.width8),
                        Text(
                      'Mã giới thiệu của bạn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                            fontSize: Dimension.font_size16,
                            color: AppColor.textPrimary,
                          ),
                      ),
                      ],
                    ),
                    SizedBox(height: Dimension.height12),
                    Container(
                      padding: EdgeInsets.all(Dimension.width16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(Dimension.radius12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _referralCode,
                            style: TextStyle(
                                fontSize: Dimension.font_size18,
                              fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyReferralCode,
                            icon: Icon(
                              Icons.copy,
                              color: AppColor.primary,
                              size: Dimension.icon20,
                            ),
                            tooltip: 'Sao chép mã',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Dimension.height12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _shareReferralCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: Dimension.height12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimension.radius8),
                          ),
                        ),
                        icon: Icon(Icons.share, size: Dimension.icon20),
                        label: Text(
                          'Chia sẻ mã giới thiệu',
                          style: TextStyle(
                            fontSize: Dimension.font_size16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Dimension.height20),
            
            // Rewards section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.green,
                          size: Dimension.icon20,
                        ),
                        SizedBox(width: Dimension.width8),
                        Text(
                          'Phần thưởng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimension.font_size16,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimension.height16),
                    _buildRewardItem(
                      icon: Icons.monetization_on,
                      iconColor: Colors.green,
                      title: 'Thưởng cho bạn',
                      description: 'Nhận 50,000 VNĐ cho mỗi bạn bè đăng ký thành công',
                    ),
                    SizedBox(height: Dimension.height12),
                    _buildRewardItem(
                      icon: Icons.card_giftcard,
                      iconColor: Colors.orange,
                      title: 'Thưởng cho bạn bè',
                      description: 'Bạn bè của bạn cũng nhận được 30,000 VNĐ',
                    ),
                    SizedBox(height: Dimension.height12),
                    _buildRewardItem(
                      icon: Icons.star,
                      iconColor: Colors.purple,
                      title: 'Thưởng đặc biệt',
                      description: 'Nhận thêm 100,000 VNĐ khi có 5 bạn bè đăng ký',
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Dimension.height20),
            
            // Invited friends section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
                child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: AppColor.primary,
                          size: Dimension.icon20,
                        ),
                        SizedBox(width: Dimension.width8),
                        Text(
                          'Bạn bè đã mời (${_invitedFriends.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                            fontSize: Dimension.font_size16,
                            color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: Dimension.height16),
                    ..._invitedFriends.map((friend) => _buildInvitedFriend(friend)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Dimension.height20),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(Dimension.width8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimension.radius8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: Dimension.icon16,
          ),
        ),
        SizedBox(width: Dimension.width12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
                  fontSize: Dimension.font_size14,
                  color: AppColor.textPrimary,
          ),
        ),
              SizedBox(height: Dimension.height4),
              Text(
                description,
                style: TextStyle(
                  fontSize: Dimension.font_size12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitedFriend(Map<String, dynamic> friend) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimension.height12),
      padding: EdgeInsets.all(Dimension.width12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Dimension.radius8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Dimension.width20,
            backgroundColor: AppColor.primary.withOpacity(0.1),
            child: Text(
              friend['name'].substring(0, 1),
              style: TextStyle(
                color: AppColor.primary,
                fontWeight: FontWeight.bold,
                fontSize: Dimension.font_size14,
              ),
            ),
          ),
          SizedBox(width: Dimension.width12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Dimension.font_size14,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: Dimension.height4),
                Text(
                  friend['phone'],
                  style: TextStyle(
                    fontSize: Dimension.font_size12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: Dimension.height4),
                Text(
                  'Ngày mời: ${friend['date']}',
                  style: TextStyle(
                    fontSize: Dimension.font_size10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimension.width8,
              vertical: Dimension.height4,
            ),
        decoration: BoxDecoration(
              color: _getStatusColor(friend['status']),
              borderRadius: BorderRadius.circular(Dimension.radius12),
        ),
        child: Text(
              friend['status'],
              style: TextStyle(
            color: Colors.white,
                fontSize: Dimension.font_size10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
