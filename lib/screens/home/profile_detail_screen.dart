import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/driver.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import 'update_profile_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({Key? key}) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshDriverProfile();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Thông tin tài xế',
          style: TextStyle(
            color: Colors.white,
            fontSize: Dimension.font_size18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white, size: Dimension.icon24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen(),
                ),
              ).then((_) => _loadProfile());
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            )
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final driver = authProvider.driver;
                if (driver == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: Dimension.icon24 * 3,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: Dimension.height16),
                        Text(
                          'Không có thông tin tài xế',
                          style: TextStyle(
                            fontSize: Dimension.font_size16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _buildProfileContent(driver);
              },
            ),
    );
  }

  Widget _buildProfileContent(Driver driver) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppColor.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header với avatar và thông tin cơ bản
            _buildProfileHeader(driver),
            SizedBox(height: Dimension.height16),

            // Thông tin cá nhân
            _buildPersonalInfoSection(driver),
            SizedBox(height: Dimension.height16),

            // Trạng thái tài khoản
            _buildAccountStatusSection(driver),
            SizedBox(height: Dimension.height16),

            // Tài liệu xác minh
            _buildDocumentsSection(driver),
            SizedBox(height: Dimension.height16),

            // Thống kê
            _buildStatsSection(driver),
            SizedBox(height: Dimension.height100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Driver driver) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: Dimension.height20),
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: Dimension.width50,
            backgroundColor: Colors.white,
            child: driver.avatar != null && driver.avatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      driver.avatar!,
                        width: Dimension.width100,
                        height: Dimension.height100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                          return Icon(
                          Icons.person,
                            size: Dimension.icon24 * 2.5,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                  : Icon(
                    Icons.person,
                      size: Dimension.icon24 * 2.5,
                    color: Colors.grey,
                    ),
                  ),
          ),
          SizedBox(height: Dimension.height12),

          // Tên và phone
          Text(
            driver.name ?? 'Chưa cập nhật tên',
            style: TextStyle(
              fontSize: Dimension.font_size26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Dimension.height4),

          Text(
            driver.phoneNumber,
            style: TextStyle(
              fontSize: Dimension.font_size16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: Dimension.height8),

          // Rating và status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (driver.reviewRate != null) ...[
                Icon(Icons.star, color: Colors.amber, size: Dimension.icon20),
                SizedBox(width: Dimension.width4),
                Text(
                  driver.reviewRate!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: Dimension.width16),
              ],
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width12,
                  vertical: Dimension.height4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(driver.status),
                  borderRadius: BorderRadius.circular(Dimension.radius12),
                ),
                child: Text(
                  _getStatusText(driver.status),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Dimension.font_size12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimension.height20),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Driver driver) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Dimension.width16),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
              'Thông tin cá nhân',
              style: TextStyle(
                    fontSize: Dimension.font_size18,
                fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
              ),
              ],
            ),
          ),
          Divider(height: 1),
          _buildInfoTile(
            icon: Icons.person_outline,
            title: 'Tên tài xế',
            value: driver.name ?? 'Chưa cập nhật',
            isEmpty: driver.name == null || driver.name!.isEmpty,
          ),
          _buildInfoTile(
            icon: Icons.phone_outlined,
            title: 'Số điện thoại',
            value: driver.phoneNumber,
          ),
          _buildInfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: driver.email ?? 'Chưa cập nhật',
            isEmpty: driver.email == null || driver.email!.isEmpty,
          ),
          _buildInfoTile(
            icon: Icons.lock_outline,
            title: 'Đặt mật khẩu',
            value: driver.hasPassword
                ? 'Đã thiết lập mật khẩu'
                : 'Thiết lập mật khẩu bảo mật',
            isEmpty: !driver.hasPassword,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusSection(Driver driver) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Dimension.width16),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
              'Trạng thái tài khoản',
              style: TextStyle(
                    fontSize: Dimension.font_size18,
                fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
              ),
              ],
            ),
          ),
          Divider(height: 1),
          _buildStatusTile(
            icon: Icons.verified_user,
            title: 'Trạng thái tài khoản',
            status: _getStatusText(driver.status),
            color: _getStatusColor(driver.status),
          ),
          if (driver.profile != null)
            _buildStatusTile(
              icon: Icons.assignment_turned_in,
              title: 'Bảo mật',
              status: driver.profile!.hasAllDocuments
                  ? 'Đã xác minh'
                  : 'Chưa hoàn thành',
              color: driver.profile!.hasAllDocuments
                  ? Colors.green
                  : Colors.orange,
            ),
          _buildStatusTile(
            icon: Icons.location_on,
            title: 'Vị trí hiện tại',
            status: driver.currentLocation != null
                ? 'Đã cập nhật'
                : 'Chưa cập nhật',
            color: driver.currentLocation != null ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(Driver driver) {
    final profile = driver.profile;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Dimension.width16),
            child: Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
              'Tài liệu xác minh',
              style: TextStyle(
                    fontSize: Dimension.font_size18,
                fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
              ),
              ],
            ),
          ),
          Divider(height: 1),
          if (profile != null) ...[
            // Progress bar
            Padding(
              padding: EdgeInsets.all(Dimension.width16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ hoàn thành',
                        style: TextStyle(
                          fontSize: Dimension.font_size14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${(profile.completionPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: Dimension.font_size14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimension.height8),
                  LinearProgressIndicator(
                    value: profile.completionPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            Divider(height: 1),

            _buildDocumentTile(
              icon: Icons.credit_card,
              title: 'CMND/CCCD mặt trước',
              isCompleted: profile.hasCmndFront,
            ),

            _buildDocumentTile(
              icon: Icons.credit_card,
              title: 'CMND/CCCD mặt sau',
              isCompleted: profile.hasCmndBack,
            ),

            _buildDocumentTile(
              icon: Icons.directions_car,
              title: 'GPLX mặt trước',
              isCompleted: profile.hasGplxFront,
            ),

            _buildDocumentTile(
              icon: Icons.directions_car,
              title: 'GPLX mặt sau',
              isCompleted: profile.hasGplxBack,
            ),

            _buildDocumentTile(
              icon: Icons.assignment,
              title: 'Đăng ký xe',
              isCompleted: profile.hasDangkyXe,
            ),

            _buildDocumentTile(
              icon: Icons.security,
              title: 'Bảo hiểm xe',
              isCompleted: profile.hasBaohiem,
            ),
          ] else
            Padding(
              padding: EdgeInsets.all(Dimension.width16),
              child: Text(
                'Chưa có thông tin tài liệu',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimension.font_size14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Driver driver) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimension.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimension.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Dimension.width16),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
              'Thống kê',
              style: TextStyle(
                    fontSize: Dimension.font_size18,
                fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
              ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(Dimension.width16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Đánh giá',
                    value: driver.reviewRate?.toStringAsFixed(1) ?? 'N/A',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: Dimension.width12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng đơn',
                    value: driver.totalOrders?.toString() ?? '0',
                    icon: Icons.assignment,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: Dimension.width16,
              right: Dimension.width16,
              bottom: Dimension.width16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Hoàn thành',
                    value: driver.completedOrders?.toString() ?? '0',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: Dimension.width12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Đã hủy',
                    value: driver.cancelledOrders?.toString() ?? '0',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isEmpty = false,
    bool showArrow = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isEmpty ? Colors.grey : AppColor.primary,
        size: Dimension.icon24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Dimension.font_size14,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: Dimension.font_size16,
          fontWeight: FontWeight.w500,
          color: isEmpty ? Colors.grey : AppColor.textPrimary,
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              size: Dimension.icon16,
              color: Colors.grey[400],
            )
          : null,
      onTap: showArrow
          ? () {
              // Handle password setup navigation
            }
          : null,
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: Dimension.icon24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Dimension.font_size14,
          color: Colors.grey,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimension.width8,
          vertical: Dimension.height4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Dimension.radius8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: Dimension.font_size12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile({
    required IconData icon,
    required String title,
    required bool isCompleted,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCompleted ? Colors.green : Colors.grey,
        size: Dimension.icon24,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: Dimension.font_size14),
      ),
      trailing: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? Colors.green : Colors.grey,
        size: Dimension.icon20,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimension.width16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimension.radius8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: Dimension.icon24),
          SizedBox(height: Dimension.height8),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimension.font_size20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: Dimension.height4),
          Text(
            title,
            style: TextStyle(
              fontSize: Dimension.font_size12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Sẵn sàng';
      case 2:
        return 'Offline';
      case 3:
        return 'Đang bận';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
