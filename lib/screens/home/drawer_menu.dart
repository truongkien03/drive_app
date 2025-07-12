import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/dimension.dart';
import '../../utils/app_color.dart';
import '../../providers/auth_provider.dart';
import 'profile_detail_screen.dart';
import 'orders_screen.dart';
import 'trip_sharing_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';
import '../../test/gps_test_screen.dart';
import '../auth/phone_input_screen.dart';
import 'notification_test_screen.dart';

class DrawerMenu extends StatelessWidget {
  final VoidCallback? onLogout;
  const DrawerMenu({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          child: Column(
            children: [
              // Header with user info
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileDetailScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.primary, AppColor.yellowColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(Dimension.radius20),
                      bottomRight: Radius.circular(Dimension.radius20),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(Dimension.width16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: Dimension.height40,
                            backgroundColor: AppColor.background,
                            child: authProvider.driver?.avatar?.isNotEmpty == true
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimension.height40),
                                    child: Image.network(
                                      authProvider.driver!.avatar!,
                                      width: Dimension.height80,
                                      height: Dimension.height80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: Dimension.height40,
                                          color: AppColor.primary,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: Dimension.height40,
                                    color: AppColor.primary,
                                  ),
                          ),
                          SizedBox(height: Dimension.height12),
                          // Name
                          Text(
                            authProvider.driver?.name ?? 'Trương Xuân Kiên',
                            style: TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: Dimension.font_size16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Dimension.height8),
                          // Phone
                          Text(
                            authProvider.driver?.phoneNumber ?? '',
                            style: TextStyle(
                              color: AppColor.textPrimary.withOpacity(0.7),
                              fontSize: Dimension.font_size14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Dimension.height8),
                          // Tap hint
                          Text(
                            '✏️ Nhấn để xem chi tiết',
                            style: TextStyle(
                              color: AppColor.textPrimary.withOpacity(0.5),
                              fontSize: Dimension.font_size14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    buildMenuItem(
                      icon: Icons.home,
                      title: 'Trang chủ',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.person,
                      title: 'Thông tin cá nhân',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileDetailScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.delivery_dining,
                      title: 'Đơn đang giao',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrdersScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.share,
                      title: 'Chia sẻ chuyến đi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TripSharingScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Thống kê',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StatisticsScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.history,
                      title: 'Lịch sử chuyến đi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.people,
                      title: 'Mời bạn bè',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const InviteFriendsScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.settings,
                      title: 'Thiết lập',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    buildMenuItem(
                      icon: Icons.location_searching,
                      title: 'GPS Test',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GPSTestScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Test Notifications',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationTestScreen()),
                        );
                      },
                    ),
                    buildMenuItem(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      onTap: () {
                        Navigator.pop(context);
                        if (onLogout != null) onLogout!();
                      },
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

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.textPrimary.withOpacity(0.7), size: Dimension.icon24),
      title: Text(
        title,
        style: TextStyle(
          color: AppColor.textPrimary,
          fontSize: Dimension.font_size16,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: Dimension.width16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius12),
      ),
      hoverColor: AppColor.primary.withOpacity(0.08),
    );
  }
} 