import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../home/home_screen.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';

class PasswordLoginScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordLoginScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.lock,
                  size: Dimension.icon48,
                  color: AppColor.primary,
                ),
                SizedBox(height: Dimension.height20),
                Text(
                  'Nhập mật khẩu',
                  style: TextStyle(
                    fontSize: Dimension.font_size20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimension.height8),
                Text(
                  'Số điện thoại: ${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: Dimension.font_size16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimension.height30),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.radius12),
                    ),
                  ),
                  validator: Validators.validatePassword,
                  onFieldSubmitted: (_) => _login(),
                ),
                SizedBox(height: Dimension.height20),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: Dimension.height16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimension.radius12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: Dimension.font_size16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),

                SizedBox(height: Dimension.height16),

                // Forgot password button
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Chức năng quên mật khẩu sẽ được cập nhật sớm'),
                      ),
                    );
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: Dimension.font_size16,
                    ),
                  ),
                ),

                SizedBox(height: Dimension.height16),

                // Login with OTP button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColor.primary),
                    padding: EdgeInsets.symmetric(vertical: Dimension.height16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimension.radius12),
                    ),
                  ),
                  child: Text(
                    'Đăng nhập bằng OTP',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: Dimension.font_size16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      return Container(
                        margin: EdgeInsets.only(top: Dimension.height16),
                        padding: EdgeInsets.all(Dimension.width12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(Dimension.radius8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: Dimension.font_size14,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.loginWithPassword(
        widget.phoneNumber,
        _passwordController.text,
      );

      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
