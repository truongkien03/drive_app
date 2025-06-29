import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/driver.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thông tin tài xế',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
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
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final driver = authProvider.driver;
                if (driver == null) {
                  return const Center(
                    child: Text('Không có thông tin tài xế'),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header với avatar và thông tin cơ bản
            _buildProfileHeader(driver),
            const SizedBox(height: 16),

            // Thông tin cá nhân
            _buildPersonalInfoSection(driver),
            const SizedBox(height: 16),

            // Trạng thái tài khoản
            _buildAccountStatusSection(driver),
            const SizedBox(height: 16),

            // Tài liệu xác minh
            _buildDocumentsSection(driver),
            const SizedBox(height: 16),

            // Thống kê
            _buildStatsSection(driver),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Driver driver) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green, Color(0xFF4CAF50)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: driver.avatar != null && driver.avatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      driver.avatar!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(height: 12),

          // Tên và phone
          Text(
            driver.name ?? 'Chưa cập nhật tên',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            driver.phoneNumber,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),

          // Rating và status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (driver.reviewRate != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  driver.reviewRate!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(driver.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(driver.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Driver driver) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Trạng thái tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tài liệu xác minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          if (profile != null) ...[
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${(profile.completionPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: profile.completionPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

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
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có thông tin tài liệu',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Driver driver) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Thống kê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
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
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                const SizedBox(width: 12),
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
        color: isEmpty ? Colors.grey : Colors.green,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isEmpty ? Colors.grey : Colors.black87,
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
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
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
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
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? Colors.green : Colors.grey,
        size: 20,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
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
