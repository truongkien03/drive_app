class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 9 || digitsOnly.length > 15) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }

    if (value.length != 4) {
      return 'Mã OTP phải có 4 chữ số';
    }

    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Mã OTP chỉ được chứa số';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    return null;
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add +84 prefix if starts with 0
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '84${digitsOnly.substring(1)}';
    }

    // Add + prefix if not present
    if (!digitsOnly.startsWith('+')) {
      digitsOnly = '+$digitsOnly';
    }

    return digitsOnly;
  }

  static String displayPhoneNumber(String phoneNumber) {
    // Remove + and country code for display
    String display = phoneNumber.replaceFirst('+84', '0');
    display = display.replaceFirst('+', '');

    // Format as 0xxx xxx xxx
    if (display.length >= 10) {
      return '${display.substring(0, 4)} ${display.substring(4, 7)} ${display.substring(7)}';
    }

    return display;
  }
}
