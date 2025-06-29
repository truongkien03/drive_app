import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
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
            const SnackBar(
              content: Text('File quá lớn. Vui lòng chọn file nhỏ hơn 10MB.'),
              backgroundColor: Colors.red,
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
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật thông tin'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thông tin cơ bản
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cơ bản',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Email không hợp lệ';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CMND/CCCD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CMND/CCCD',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Mặt trước',
                                  image: _cmndFrontImage,
                                  onTap: () => _pickImage(ImageType.cmndFront),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Mặt sau',
                                  image: _cmndBackImage,
                                  onTap: () => _pickImage(ImageType.cmndBack),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPLX
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giấy phép lái xe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Mặt trước',
                                  image: _gplxFrontImage,
                                  onTap: () => _pickImage(ImageType.gplxFront),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Mặt sau',
                                  image: _gplxBackImage,
                                  onTap: () => _pickImage(ImageType.gplxBack),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Giấy tờ xe
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giấy tờ xe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Đăng ký xe',
                                  image: _dangkyXeImage,
                                  onTap: () => _pickImage(ImageType.dangkyXe),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ImagePickerWidget(
                                  title: 'Bảo hiểm xe',
                                  image: _baohiemImage,
                                  onTap: () => _pickImage(ImageType.baohiem),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút cập nhật
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Đang cập nhật...'),
                            ],
                          )
                        : const Text(
                            'Cập nhật thông tin',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  if (authProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
        const SnackBar(
          content: Text('Vui lòng thực hiện thay đổi trước khi cập nhật.'),
          backgroundColor: Colors.orange,
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

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
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
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return success result to parent screen
        Navigator.pop(context, 'updated');
      }
    }
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final String title;
  final File? image;
  final VoidCallback onTap;

  const _ImagePickerWidget({
    required this.title,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
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
