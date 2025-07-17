import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';
import '../../config/app_config.dart';
import '../home/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.isLogin,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = AppConfig.otpTimeoutSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = AppConfig.otpTimeoutSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _verifyOTP() async {
    if (_otpController.text.length != AppConfig.otpLength) {
      _showErrorDialog('Vui lòng nhập đầy đủ mã OTP');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (widget.isLogin) {
      success =
          await authProvider.login(widget.phoneNumber, _otpController.text);
    } else {
      success =
          await authProvider.register(widget.phoneNumber, _otpController.text);
    }

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showErrorDialog(authProvider.error ?? 'Mã OTP không đúng');
    }
  }

  void _resendOTP() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (widget.isLogin) {
      success = await authProvider.sendLoginOtp(widget.phoneNumber);
    } else {
      success = await authProvider.sendRegisterOtp(widget.phoneNumber);
    }

    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP đã được gửi lại'),
          backgroundColor: AppColor.primary,
        ),
      );
    } else {
      _showErrorDialog(authProvider.error ?? 'Không thể gửi lại mã OTP');
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text('Xác thực OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Dimension.width16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Icon
              Icon(
                Icons.sms,
                size: Dimension.icon48 * 1.6,
                color: AppColor.primary,
              ),

              const SizedBox(height: 32),

              Text(
                'Xác thực số điện thoại',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                  fontSize: Dimension.font_size20,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Mã OTP đã được gửi đến\n${widget.phoneNumber}',
                style: TextStyle(
                  color: AppColor.textColor,
                  fontSize: Dimension.font_size14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // OTP Input
              PinCodeTextField(
                appContext: context,
                length: AppConfig.otpLength,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(Dimension.radius8),
                  fieldHeight: Dimension.height50,
                  fieldWidth: Dimension.width50,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: AppColor.primary,
                  inactiveColor: AppColor.backgroundColor,
                  selectedColor: AppColor.primary,
                ),
                enableActiveFill: true,
                onCompleted: (value) {
                  _verifyOTP();
                },
                onChanged: (value) {
                  // Handle change
                },
              ),

              SizedBox(height: Dimension.height30),

              // Verify button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: Dimension.height50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: 16),
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
                          : const Text(
                              'Xác thực',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  );
                },
              ),

              SizedBox(height: Dimension.height20),

              // Timer and resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    Text(
                      'Gửi lại mã sau ',
                      style: TextStyle(
                        color: AppColor.textColor,
                        fontSize: Dimension.font_size14,
                      ),
                    ),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        color: AppColor.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: Dimension.font_size14,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Không nhận được mã? ',
                      style: TextStyle(
                        color: AppColor.textColor,
                        fontSize: Dimension.font_size14,
                      ),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return TextButton(
                          onPressed: authProvider.isLoading ? null : _resendOTP,
                          child: const Text(
                            'Gửi lại',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Change phone number
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Thay đổi số điện thoại',
                    style: TextStyle(
                      color: AppColor.textColor,
                      decoration: TextDecoration.underline,
                      fontSize: Dimension.font_size14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
