import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/app_theme.dart';
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
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Logo or Icon
              Icon(
                Icons.local_shipping,
                size: 80,
                color: AppColors.primary,
              ),

              const SizedBox(height: 32),

              Text(
                widget.isLogin ? 'Đăng nhập tài xế' : 'Đăng ký tài xế',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Nhập số điện thoại để nhận mã OTP',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

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
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
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

                        const SizedBox(width: 8),

                        // Phone number field
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              hintText: 'Nhập số điện thoại',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: Validators.validatePhoneNumber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Send OTP button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _sendOTP,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Gửi mã OTP',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        );
                      },
                    ),

                    // Login with password button (only show in login mode)
                    if (widget.isLogin) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
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
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                          child: const Text(
                            'Đăng nhập bằng mật khẩu',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

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
    );
  }
}
