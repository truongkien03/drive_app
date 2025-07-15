import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColor.primary,
                      AppColor.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(Dimension.width20),
                  child: Column(
                    children: [
                      // Back button and title
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: Dimension.icon24,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Đặt mật khẩu',
                              style: TextStyle(
                                fontSize: Dimension.font_size20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
              ),
                          ),
                          SizedBox(width: Dimension.width50), // Balance the back button
                        ],
                      ),
                      SizedBox(height: Dimension.height20),
                      
                      // Header content
                      Container(
                        padding: EdgeInsets.all(Dimension.width20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimension.radius16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: Dimension.icon48,
                              color: Colors.white,
                            ),
                            SizedBox(height: Dimension.height16),
                            Text(
                              'Bảo mật tài khoản',
                style: TextStyle(
                                fontSize: Dimension.font_size18,
                  fontWeight: FontWeight.bold,
                                color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
                            SizedBox(height: Dimension.height8),
              Text(
                              'Tạo mật khẩu mạnh để bảo vệ tài khoản của bạn',
                style: TextStyle(
                                fontSize: Dimension.font_size14,
                                color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form content
              Padding(
                padding: EdgeInsets.all(Dimension.width20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: Dimension.height20),

                      // Password field card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Dimension.radius16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(Dimension.width16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: AppColor.primary,
                                    size: Dimension.icon20,
                                  ),
                                  SizedBox(width: Dimension.width8),
                                  Text(
                                    'Mật khẩu mới',
                                    style: TextStyle(
                                      fontSize: Dimension.font_size16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Dimension.height12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                                style: TextStyle(fontSize: Dimension.font_size16),
                decoration: InputDecoration(
                                  hintText: 'Nhập mật khẩu mới',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: Dimension.font_size14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: AppColor.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: Colors.red, width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Dimension.width16,
                                    vertical: Dimension.height12,
                                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                      size: Dimension.icon20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: Dimension.height16),

                      // Confirm password field card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Dimension.radius16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(Dimension.width16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: AppColor.primary,
                                    size: Dimension.icon20,
                                  ),
                                  SizedBox(width: Dimension.width8),
                                  Text(
                                    'Xác nhận mật khẩu',
                                    style: TextStyle(
                                      fontSize: Dimension.font_size16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Dimension.height12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                                style: TextStyle(fontSize: Dimension.font_size16),
                decoration: InputDecoration(
                                  hintText: 'Nhập lại mật khẩu',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: Dimension.font_size14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: AppColor.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Dimension.radius12),
                                    borderSide: BorderSide(color: Colors.red, width: 1),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Dimension.width16,
                                    vertical: Dimension.height12,
                                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                      size: Dimension.icon20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: Dimension.height20),

                      // Password requirements card
              Container(
                decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(Dimension.radius16),
                          border: Border.all(color: Colors.blue[200]!),
                ),
                        child: Padding(
                          padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: Colors.blue[700],
                                    size: Dimension.icon20,
                                  ),
                                  SizedBox(width: Dimension.width8),
                    Text(
                                    'Yêu cầu mật khẩu',
                      style: TextStyle(
                                      fontSize: Dimension.font_size16,
                        fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                      ),
                    ),
                                ],
                              ),
                              SizedBox(height: Dimension.height12),
                              _buildRequirement('Ít nhất 6 ký tự', Icons.check_circle_outline),
                              _buildRequirement('Chứa ít nhất 1 chữ cái', Icons.abc),
                              _buildRequirement('Chứa ít nhất 1 số', Icons.numbers),
                              _buildRequirement('Mật khẩu mạnh và khó đoán', Icons.shield),
                  ],
                ),
              ),
                      ),

                      SizedBox(height: Dimension.height30),

                      // Submit button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                          return Container(
                            width: double.infinity,
                            height: Dimension.height50,
                            child: ElevatedButton(
                              onPressed: (authProvider.isLoading || _isSubmitting) ? null : _setPassword,
                    style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                                elevation: 0,
                      shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Dimension.radius12),
                      ),
                    ),
                              child: (authProvider.isLoading || _isSubmitting)
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: Dimension.icon20,
                                          height: Dimension.icon20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                                        ),
                                        SizedBox(width: Dimension.width12),
                                        Text(
                                          'Đang xử lý...',
                                          style: TextStyle(
                                            fontSize: Dimension.font_size16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                          )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_outline,
                                          size: Dimension.icon20,
                                        ),
                                        SizedBox(width: Dimension.width8),
                                        Text(
                            'Đặt mật khẩu',
                            style: TextStyle(
                                            fontSize: Dimension.font_size16,
                              fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                            ),
                          ),
                  );
                },
              ),

                      SizedBox(height: Dimension.height16),

              // Error message
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.error != null) {
                    return Container(
                              padding: EdgeInsets.all(Dimension.width12),
                      decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(Dimension.radius12),
                                border: Border.all(color: Colors.red[200]!),
                      ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: Dimension.icon20,
                                  ),
                                  SizedBox(width: Dimension.width8),
                                  Expanded(
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: Dimension.font_size14,
                                      ),
                        ),
                                  ),
                                ],
                      ),
                    );
                  }
                          return SizedBox.shrink();
                },
                      ),

                      SizedBox(height: Dimension.height20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimension.height4),
      child: Row(
        children: [
          Icon(
            icon,
            size: Dimension.icon16,
            color: Colors.blue[600],
          ),
          SizedBox(width: Dimension.width8),
          Expanded(
            child: Text(
            text,
            style: TextStyle(
                color: Colors.blue[700],
                fontSize: Dimension.font_size14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.setPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      );

        if (success && mounted) {
          // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: Dimension.width8),
                  Text('Đặt mật khẩu thành công!'),
                ],
              ),
            backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
          ),
        );

        // Return success result to parent screen
        Navigator.pop(context, 'updated');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: Dimension.width8),
                  Text('Lỗi: $e'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
