import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import '../../utils/profile_update_test_helper.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referenceCodeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // 6 ảnh tài liệu tài xế cần upload
  File? _cmndFrontImage; // CMND mặt trước
  File? _cmndBackImage; // CMND mặt sau
  File? _gplxFrontImage; // GPLX mặt trước
  File? _gplxBackImage; // GPLX mặt sau
  File? _dangkyXeImage; // Đăng ký xe
  File? _baohiemImage; // Bảo hiểm xe

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driver = authProvider.driver;

    if (driver != null) {
      _nameController.text = driver.name ?? '';
      _emailController.text = driver.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referenceCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageType type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image == null) return;

      final File file = File(image.path);
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ File quá lớn. Vui lòng chọn file nhỏ hơn 10MB.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        switch (type) {
          case ImageType.cmndFront:
            _cmndFrontImage = file;
            break;
          case ImageType.cmndBack:
            _cmndBackImage = file;
            break;
          case ImageType.gplxFront:
            _gplxFrontImage = file;
            break;
          case ImageType.gplxBack:
            _gplxBackImage = file;
            break;
          case ImageType.dangkyXe:
            _dangkyXeImage = file;
            break;
          case ImageType.baohiem:
            _baohiemImage = file;
            break;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Cập nhật thông tin',
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Dimension.width16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
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
                                'Cập nhật thông tin cá nhân',
                            style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Dimension.font_size18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                              SizedBox(height: Dimension.height8),
                              Text(
                                'Cập nhật thông tin và tài liệu xác minh',
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
                  
                  // Basic Information Section
                  _buildBasicInfoSection(),
                  
                  SizedBox(height: Dimension.height20),
                  
                  // CMND/CCCD Section
                  _buildCMNDSection(),
                  
                  SizedBox(height: Dimension.height20),
                  
                  // GPLX Section
                  _buildGPLXSection(),
                  
                  SizedBox(height: Dimension.height20),
                  
                  // Vehicle Documents Section
                  _buildVehicleDocumentsSection(),
                  
                  SizedBox(height: Dimension.height20),
                  
                  // Debug Test Button (only in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    _buildDebugTestSection(),
                  
                  SizedBox(height: Dimension.height20),
                  
                  // Update Button
                  _buildUpdateButton(authProvider),
                  
                  // Error Display
                  if (authProvider.error != null)
                    _buildErrorDisplay(authProvider.error!),
                  
                  SizedBox(height: Dimension.height20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
                  Icons.person_outline,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                  'Thông tin cơ bản',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height16),
            _buildTextField(
                            controller: _nameController,
              label: 'Họ và tên',
              icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
            SizedBox(height: Dimension.height16),
            _buildTextField(
                            controller: _emailController,
              label: 'Email',
              icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Email không hợp lệ';
                                }
                              }
                              return null;
                            },
                          ),
            SizedBox(height: Dimension.height16),
            _buildTextField(
                            controller: _referenceCodeController,
              label: 'Mã giới thiệu (tùy chọn)',
              icon: Icons.card_giftcard,
                              hintText: 'Nhập mã giới thiệu nếu có',
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCMNDSection() {
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
                  Icons.credit_card,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                            'CMND/CCCD',
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
                  child: _buildImagePickerWidget(
                                  title: 'Mặt trước',
                                  image: _cmndFrontImage,
                                  onTap: () => _pickImage(ImageType.cmndFront),
                    icon: Icons.credit_card,
                                ),
                              ),
                SizedBox(width: Dimension.width16),
                              Expanded(
                  child: _buildImagePickerWidget(
                                  title: 'Mặt sau',
                                  image: _cmndBackImage,
                                  onTap: () => _pickImage(ImageType.cmndBack),
                    icon: Icons.credit_card,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildGPLXSection() {
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
                            'Giấy phép lái xe',
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
                  child: _buildImagePickerWidget(
                                  title: 'Mặt trước',
                                  image: _gplxFrontImage,
                                  onTap: () => _pickImage(ImageType.gplxFront),
                    icon: Icons.directions_car,
                                ),
                              ),
                SizedBox(width: Dimension.width16),
                              Expanded(
                  child: _buildImagePickerWidget(
                                  title: 'Mặt sau',
                                  image: _gplxBackImage,
                                  onTap: () => _pickImage(ImageType.gplxBack),
                    icon: Icons.directions_car,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildVehicleDocumentsSection() {
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
                  Icons.description,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
                            'Giấy tờ xe',
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
                  child: _buildImagePickerWidget(
                                  title: 'Đăng ký xe',
                                  image: _dangkyXeImage,
                                  onTap: () => _pickImage(ImageType.dangkyXe),
                    icon: Icons.description,
                                ),
                              ),
                SizedBox(width: Dimension.width16),
                              Expanded(
                  child: _buildImagePickerWidget(
                                  title: 'Bảo hiểm xe',
                                  image: _baohiemImage,
                                  onTap: () => _pickImage(ImageType.baohiem),
                    icon: Icons.security,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDebugTestSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.radius8),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width12),
        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ProfileUpdateTestHelper.testProfileUpdateAPI(
                              name: _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()
                                  : null,
                              email: _emailController.text.trim().isNotEmpty
                                  ? _emailController.text.trim()
                                  : null,
              referenceCode: _referenceCodeController.text.trim().isNotEmpty
                                  ? _referenceCodeController.text.trim()
                                  : null,
                              gplxFrontImagePath: _gplxFrontImage?.path,
                              gplxBackImagePath: _gplxBackImage?.path,
                              baohiemImagePath: _baohiemImage?.path,
                              dangkyXeImagePath: _dangkyXeImage?.path,
                              cmndFrontImagePath: _cmndFrontImage?.path,
                              cmndBackImagePath: _cmndBackImage?.path,
                            );
                          },
          icon: Icon(Icons.bug_report, size: Dimension.icon16),
          label: Text('Test API (Debug)', style: TextStyle(fontSize: Dimension.font_size12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: BorderSide(color: Colors.orange),
          ),
                    ),
      ),
    );
  }

  Widget _buildUpdateButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: Dimension.height16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimension.radius8),
          ),
          elevation: 4,
                    ),
                    child: authProvider.isLoading
            ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                    width: Dimension.icon20,
                    height: Dimension.icon20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                  SizedBox(width: Dimension.width12),
                  Text(
                    'Đang cập nhật...',
                    style: TextStyle(
                      fontSize: Dimension.font_size16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                            ],
                          )
            : Text(
                            'Cập nhật thông tin',
                style: TextStyle(
                  fontSize: Dimension.font_size16,
                  fontWeight: FontWeight.bold,
                ),
                          ),
                  ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: EdgeInsets.all(Dimension.width12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(Dimension.radius8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: Dimension.icon16),
          SizedBox(width: Dimension.width8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: Dimension.font_size14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColor.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius8),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimension.width12,
          vertical: Dimension.height12,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildImagePickerWidget({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Dimension.height120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(Dimension.radius8),
          color: Colors.grey.shade50,
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimension.radius8),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: Dimension.height4,
                    left: Dimension.width4,
                    right: Dimension.width4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width8,
                        vertical: Dimension.height4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                                                 borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Dimension.font_size10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Positioned(
                    top: Dimension.height4,
                    right: Dimension.width4,
                    child: Container(
                      padding: EdgeInsets.all(Dimension.width4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                                                 size: 12,
                      ),
                      ),
                    ),
                  ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimension.width8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimension.radius8),
                    ),
                    child: Icon(
                      icon,
                      size: Dimension.icon24,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(height: Dimension.height8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: Dimension.font_size12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Dimension.height4),
                  Text(
                    'Chạm để chọn',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: Dimension.font_size10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  bool get _hasChanges {
    if (_nameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty) {
      return true;
    }

    return _cmndFrontImage != null ||
        _cmndBackImage != null ||
        _gplxFrontImage != null ||
        _gplxBackImage != null ||
        _dangkyXeImage != null ||
        _baohiemImage != null;
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Vui lòng thực hiện thay đổi trước khi cập nhật.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Debug log để kiểm tra dữ liệu từ UI
    print('🖥️ ===== UPDATE PROFILE FROM UI =====');
    print('👤 Name from UI: "${_nameController.text.trim()}"');
    print('📧 Email from UI: "${_emailController.text.trim()}"');
    print('📷 CMND Front Image: ${_cmndFrontImage?.path}');
    print('📷 CMND Back Image: ${_cmndBackImage?.path}');
    print('🚗 GPLX Front Image: ${_gplxFrontImage?.path}');
    print('🚗 GPLX Back Image: ${_gplxBackImage?.path}');
    print('📄 Dangky Xe Image: ${_dangkyXeImage?.path}');
    print('🛡️ Baohiem Image: ${_baohiemImage?.path}');

    final success = await authProvider.updateProfileWithFiles(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      referenceCode: _referenceCodeController.text.trim().isNotEmpty
          ? _referenceCodeController.text.trim()
          : null,
      cmndFrontImagePath: _cmndFrontImage?.path,
      cmndBackImagePath: _cmndBackImage?.path,
      gplxFrontImagePath: _gplxFrontImage?.path,
      gplxBackImagePath: _gplxBackImage?.path,
      dangkyXeImagePath: _dangkyXeImage?.path,
      baohiemImagePath: _baohiemImage?.path,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Return success result to parent screen
        Navigator.pop(context, 'updated');
      }
    }
  }
}

enum ImageType {
  cmndFront, // CMND mặt trước
  cmndBack, // CMND mặt sau
  gplxFront, // GPLX mặt trước
  gplxBack, // GPLX mặt sau
  dangkyXe, // Đăng ký xe
  baohiem, // Bảo hiểm xe
}
