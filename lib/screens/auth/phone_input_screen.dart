import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import 'otp_verification_screen.dart';
import 'password_login_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  final bool isLogin;

  const PhoneInputScreen({
    Key? key,
    required this.isLogin,
  }) : super(key: key);

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+84';

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneNumber();
  }

  void _loadSavedPhoneNumber() async {
    // You could load saved phone number here if needed
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = '$_countryCode${_phoneController.text.trim()}';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (widget.isLogin) {
      success = await authProvider.sendLoginOtp(phoneNumber);
    } else {
      success = await authProvider.sendRegisterOtp(phoneNumber);
    }

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            phoneNumber: phoneNumber,
            isLogin: widget.isLogin,
          ),
        ),
      );
    } else {
      _showErrorDialog(authProvider.error ?? 'Có lỗi xảy ra');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Đăng nhập' : 'Đăng ký'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Dimension.width16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: Dimension.height30),

                // Logo or Icon
                Icon(
                  Icons.local_shipping,
                  size: Dimension.icon48,
                  color: AppColor.primary,
                ),

                SizedBox(height: Dimension.height30),

                Text(
                  widget.isLogin ? 'Đăng nhập tài xế' : 'Đăng ký tài xế',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                    fontSize: Dimension.font_size20,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: Dimension.height8),

                Text(
                  'Nhập số điện thoại để nhận mã OTP',
                  style: TextStyle(
                    color: AppColor.textColor,
                    fontSize: Dimension.font_size16,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: Dimension.height30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Phone number input
                      Row(
                        children: [
                          // Country code picker
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColor.textColor),
                              borderRadius: BorderRadius.circular(Dimension.radius8),
                            ),
                            child: CountryCodePicker(
                              onChanged: (countryCode) {
                                setState(() {
                                  _countryCode = countryCode.dialCode!;
                                });
                              },
                              initialSelection: 'VN',
                              favorite: const ['+84', 'VN'],
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                            ),
                          ),

                          SizedBox(width: Dimension.width8),

                          // Phone number field
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                hintText: 'Nhập số điện thoại',
                                prefixIcon: Icon(Icons.phone, color: AppColor.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Dimension.radius12),
                                ),
                              ),
                              validator: Validators.validatePhoneNumber,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Dimension.height30),

                      // Send OTP button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: Dimension.height50,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _sendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Dimension.radius12),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Gửi mã OTP',
                                      style: TextStyle(fontSize: Dimension.font_size16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          );
                        },
                      ),

                      // Login with password button (only show in login mode)
                      if (widget.isLogin) ...[
                        SizedBox(height: Dimension.height16),
                        SizedBox(
                          width: double.infinity,
                          height: Dimension.height50,
                          child: OutlinedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final phoneNumber = Validators.formatPhoneNumber(
                                    _countryCode + _phoneController.text);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PasswordLoginScreen(
                                      phoneNumber: phoneNumber,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColor.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimension.radius12),
                              ),
                            ),
                            child: Text(
                              'Đăng nhập bằng mật khẩu',
                              style: TextStyle(fontSize: Dimension.font_size16, color: AppColor.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: Dimension.height30),

                // Switch between login/register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isLogin
                          ? 'Chưa có tài khoản? '
                          : 'Đã có tài khoản? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhoneInputScreen(
                              isLogin: !widget.isLogin,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        widget.isLogin ? 'Đăng ký' : 'Đăng nhập',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
