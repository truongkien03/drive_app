import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
      appBar: AppBar(
        title: const Text('Thiết lập'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadDriverProfile,
            tooltip: 'Tải lại dữ liệu',
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        color: Colors.green,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Column(
                          children: [
                            _buildSettingItem(
                              icon: Icons.person,
                              title: 'Tên tài xế',
                              subtitle:
                                  authProvider.driver?.name ?? 'Chưa cập nhật',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdateProfileScreen(),
                                  ),
                                );
                                // Reload data when returning from update profile
                                if (result == true || result == 'updated') {
                                  await _loadDriverProfile();
                                }
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.phone,
                              title: 'Số điện thoại',
                              subtitle: authProvider.driver?.phoneNumber ??
                                  'Chưa cập nhật',
                              onTap: () {
                                // TODO: Edit phone
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.email,
                              title: 'Email',
                              subtitle:
                                  authProvider.driver?.email ?? 'Chưa cập nhật',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdateProfileScreen(),
                                  ),
                                );
                                // Reload data when returning from update profile
                                if (result == true || result == 'updated') {
                                  await _loadDriverProfile();
                                }
                              },
                            ),
                            // Show different options based on password status
                            if (authProvider.driver?.hasPassword != true)
                              _buildSettingItem(
                                icon: Icons.lock,
                                title: 'Đặt mật khẩu',
                                subtitle: 'Thiết lập mật khẩu bảo mật',
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SetPasswordScreen(),
                                    ),
                                  );
                                  // Reload data when returning from set password
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
                                      builder: (context) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  );
                                  // Reload data when returning from change password
                                  if (result == true || result == 'updated') {
                                    await _loadDriverProfile();
                                  }
                                },
                              ),
                            _buildSettingItem(
                              icon: Icons.verified_user,
                              title: 'Trạng thái tài khoản',
                              subtitle: authProvider.driver?.statusText ??
                                  'Không xác định',
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
                                    builder: (context) =>
                                        const SetPasswordScreen(),
                                  ),
                                );
                                // Reload data when returning from set password
                                if (result == true || result == 'updated') {
                                  await _loadDriverProfile();
                                }
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.location_on,
                              title: 'Vị trí hiện tại',
                              subtitle: authProvider
                                      .driver?.currentLocation?.address ??
                                  'Chưa cập nhật',
                              onTap: () {
                                // TODO: Location settings
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.description,
                              title: 'Tài liệu xác minh',
                              subtitle:
                                  authProvider.driver?.profile?.isVerified ==
                                          true
                                      ? 'Đã xác minh'
                                      : 'Chưa nộp tài liệu',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdateProfileScreen(),
                                  ),
                                );
                                // Reload data when returning from update profile
                                if (result == true || result == 'updated') {
                                  await _loadDriverProfile();
                                }
                              },
                            ),
                            if (authProvider.driver?.reviewRate != null)
                              _buildSettingItem(
                                icon: Icons.star,
                                title: 'Đánh giá',
                                subtitle:
                                    '${authProvider.driver!.reviewRate!.toStringAsFixed(1)} ⭐',
                                onTap: () {
                                  // TODO: View reviews
                                },
                              ),
                            if (authProvider.driver?.vehicleInfo != null)
                              _buildSettingItem(
                                icon: Icons.directions_car,
                                title: 'Thông tin xe',
                                subtitle: authProvider
                                    .driver!.vehicleInfo!.displayName,
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
            ),
            const SizedBox(height: 16),

            // Thống kê section
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.driver?.totalOrders == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thống kê',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Hoàn thành',
                                '${authProvider.driver!.completedOrders ?? 0}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
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
            ),
            const SizedBox(height: 16),

            // App settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt ứng dụng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Thông báo'),
                      subtitle: const Text('Nhận thông báo về đơn hàng mới'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      title: const Text('Vị trí'),
                      subtitle: const Text('Chia sẻ vị trí để nhận đơn hàng'),
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _locationEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      title: const Text('Tự động nhận đơn'),
                      subtitle:
                          const Text('Tự động chấp nhận đơn hàng phù hợp'),
                      value: _autoAcceptOrders,
                      onChanged: (value) {
                        setState(() {
                          _autoAcceptOrders = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin xe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      icon: Icons.directions_car,
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
            ),
            const SizedBox(height: 16),

            // Other settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Khác',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      icon: Icons.help,
                      title: 'Trợ giúp',
                      subtitle: 'Câu hỏi thường gặp và hỗ trợ',
                      onTap: () {
                        // TODO: Show help
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.info,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản 1.0.0',
                      onTap: () {
                        // TODO: Show about
                      },
                    ),
                  ],
                ),
              ),
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
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
