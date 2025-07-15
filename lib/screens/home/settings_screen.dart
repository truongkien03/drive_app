import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import 'set_password_screen.dart';
import 'update_profile_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _autoAcceptOrders = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Thiết lập',
          style: TextStyle(
            fontSize: Dimension.font_size18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
              size: Dimension.icon20,
            ),
            onPressed: _isRefreshing ? null : _loadDriverProfile,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        color: AppColor.primary,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Dimension.width16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section
              _buildProfileHeader(),
              
              SizedBox(height: Dimension.height20),
              
              // Personal Information Section
              _buildPersonalInfoSection(),
              
              SizedBox(height: Dimension.height20),
              
              // Statistics Section
              _buildStatisticsSection(),
              
              SizedBox(height: Dimension.height20),
              
              // App Settings Section
              _buildAppSettingsSection(),
              
              SizedBox(height: Dimension.height20),
              
              // Vehicle Information Section
              _buildVehicleInfoSection(),
              
              SizedBox(height: Dimension.height20),
              
              // Other Settings Section
              _buildOtherSettingsSection(),
              
              SizedBox(height: Dimension.height20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final driver = authProvider.driver;
        return Container(
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
              CircleAvatar(
                radius: Dimension.width30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
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
                      driver?.name ?? 'Tài xế',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimension.font_size18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Dimension.height4),
                    Text(
                      driver?.phoneNumber ?? 'Chưa cập nhật',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: Dimension.font_size14,
                      ),
                    ),
                    SizedBox(height: Dimension.height8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width8,
                        vertical: Dimension.height4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(Dimension.radius8),
                      ),
                      child: Text(
                        driver?.statusText ?? 'Không xác định',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Dimension.font_size12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (driver?.reviewRate != null)
                Container(
                  padding: EdgeInsets.all(Dimension.width8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Dimension.radius8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: Dimension.icon16,
                      ),
                      SizedBox(width: Dimension.width4),
                      Text(
                        driver!.reviewRate!.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Dimension.font_size14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
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
                  Icons.person,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.person_outline,
                      title: 'Tên tài xế',
                      subtitle: authProvider.driver?.name ?? 'Chưa cập nhật',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateProfileScreen(),
                          ),
                        );
                        if (result == true || result == 'updated') {
                          await _loadDriverProfile();
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.phone,
                      title: 'Số điện thoại',
                      subtitle: authProvider.driver?.phoneNumber ?? 'Chưa cập nhật',
                      onTap: () {
                        // TODO: Edit phone
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: authProvider.driver?.email ?? 'Chưa cập nhật',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateProfileScreen(),
                          ),
                        );
                        if (result == true || result == 'updated') {
                          await _loadDriverProfile();
                        }
                      },
                    ),
                    if (authProvider.driver?.hasPassword != true)
                      _buildSettingItem(
                        icon: Icons.lock_outline,
                        title: 'Đặt mật khẩu',
                        subtitle: 'Thiết lập mật khẩu bảo mật',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetPasswordScreen(),
                            ),
                          );
                          if (result == true || result == 'updated') {
                            await _loadDriverProfile();
                          }
                        },
                      ),
                    if (authProvider.driver?.hasPassword == true)
                      _buildSettingItem(
                        icon: Icons.lock_reset,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Thay đổi mật khẩu hiện tại',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                          if (result == true || result == 'updated') {
                            await _loadDriverProfile();
                          }
                        },
                      ),
                    _buildSettingItem(
                      icon: Icons.verified_user,
                      title: 'Trạng thái tài khoản',
                      subtitle: authProvider.driver?.statusText ?? 'Không xác định',
                      onTap: () {
                        // TODO: Account status management
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.security,
                      title: 'Bảo mật',
                      subtitle: authProvider.driver?.hasPassword == true
                          ? 'Đã thiết lập mật khẩu'
                          : 'Chưa thiết lập mật khẩu',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SetPasswordScreen(),
                          ),
                        );
                        if (result == true || result == 'updated') {
                          await _loadDriverProfile();
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.location_on,
                      title: 'Vị trí hiện tại',
                      subtitle: authProvider.driver?.currentLocation?.address ?? 'Chưa cập nhật',
                      onTap: () {

                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.description,
                      title: 'Tài liệu xác minh',
                      subtitle: authProvider.driver?.profile?.isVerified == true
                          ? 'Đã xác minh'
                          : 'Chưa nộp tài liệu',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateProfileScreen(),
                          ),
                        );
                        if (result == true || result == 'updated') {
                          await _loadDriverProfile();
                        }
                      },
                    ),
                    if (authProvider.driver?.vehicleInfo != null)
                      _buildSettingItem(
                        icon: Icons.directions_car,
                        title: 'Thông tin xe',
                        subtitle: authProvider.driver!.vehicleInfo!.displayName,
                        onTap: () {
                          // TODO: Vehicle info screen
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.driver?.totalOrders == null) {
          return SizedBox.shrink();
        }

        return Card(
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
                      Icons.analytics,
                      color: AppColor.primary,
                      size: Dimension.icon20,
                    ),
                    SizedBox(width: Dimension.width8),
                    Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: Dimension.font_size16,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimension.height16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tổng đơn',
                        '${authProvider.driver!.totalOrders}',
                        Icons.assignment,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: Dimension.width8),
                    Expanded(
                      child: _buildStatCard(
                        'Hoàn thành',
                        '${authProvider.driver!.completedOrders ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: Dimension.width8),
                    Expanded(
                      child: _buildStatCard(
                        'Bị hủy',
                        '${authProvider.driver!.cancelledOrders ?? 0}',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppSettingsSection() {
    return Card(
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
                  Icons.settings,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                  'Cài đặt ứng dụng',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            _buildSwitchSettingItem(
              icon: Icons.notifications,
              title: 'Thông báo',
              subtitle: 'Nhận thông báo về đơn hàng mới',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            _buildSwitchSettingItem(
              icon: Icons.location_on,
              title: 'Vị trí',
              subtitle: 'Chia sẻ vị trí để nhận đơn hàng',
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
              },
            ),
            _buildSwitchSettingItem(
              icon: Icons.auto_awesome,
              title: 'Tự động nhận đơn',
              subtitle: 'Tự động chấp nhận đơn hàng phù hợp',
              value: _autoAcceptOrders,
              onChanged: (value) {
                setState(() {
                  _autoAcceptOrders = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return Card(
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
                  Icons.directions_car,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                  'Thông tin xe',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            _buildSettingItem(
              icon: Icons.directions_car_outlined,
              title: 'Loại xe',
              subtitle: 'Honda Wave Alpha',
              onTap: () {
                // TODO: Edit vehicle type
              },
            ),
            _buildSettingItem(
              icon: Icons.confirmation_number,
              title: 'Biển số xe',
              subtitle: '29A1-12345',
              onTap: () {
                // TODO: Edit license plate
              },
            ),
            _buildSettingItem(
              icon: Icons.color_lens,
              title: 'Màu xe',
              subtitle: 'Đỏ',
              onTap: () {
                // TODO: Edit vehicle color
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSettingsSection() {
    return Card(
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
                  Icons.more_horiz,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                  'Khác',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Trợ giúp',
              subtitle: 'Câu hỏi thường gặp và hỗ trợ',
              onTap: () {
                // TODO: Show help
              },
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Về ứng dụng',
              subtitle: 'Phiên bản 1.0.0',
              onTap: () {
                // TODO: Show about
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimension.height8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Dimension.radius8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimension.width12,
          vertical: Dimension.height4,
        ),
        leading: Container(
          padding: EdgeInsets.all(Dimension.width8),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimension.radius8),
          ),
          child: Icon(
            icon,
            color: AppColor.primary,
            size: Dimension.icon16,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Dimension.font_size14,
            color: AppColor.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: Dimension.font_size12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: Dimension.icon16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimension.height8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Dimension.radius8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimension.width12,
          vertical: Dimension.height4,
        ),
        leading: Container(
          padding: EdgeInsets.all(Dimension.width8),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimension.radius8),
          ),
          child: Icon(
            icon,
            color: AppColor.primary,
            size: Dimension.icon16,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Dimension.font_size14,
            color: AppColor.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: Dimension.font_size12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Dimension.width12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimension.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: Dimension.icon20,
          ),
          SizedBox(height: Dimension.height8),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimension.font_size16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: Dimension.height4),
          Text(
            title,
            style: TextStyle(
              fontSize: Dimension.font_size10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
