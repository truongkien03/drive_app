import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class TokenDebugScreen extends StatefulWidget {
  const TokenDebugScreen({Key? key}) : super(key: key);

  @override
  State<TokenDebugScreen> createState() => _TokenDebugScreenState();
}

class _TokenDebugScreenState extends State<TokenDebugScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _runDebug();
  }

  Future<void> _runDebug() async {
    final debugBuffer = StringBuffer();

    debugBuffer.writeln('🔍 TOKEN DEBUG ANALYSIS');
    debugBuffer.writeln('=' * 40);

    // Check SharedPreferences keys
    debugBuffer.writeln('💾 SharedPreferences Debug:');
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      debugBuffer.writeln('  - Available keys: $keys');

      final accessToken = prefs.getString('accessToken');
      final driverToken = prefs.getString('driver_access_token');
      final authToken = prefs.getString('auth_token');

      debugBuffer.writeln(
          '  - accessToken: ${accessToken?.substring(0, 30) ?? 'NULL'}...');
      debugBuffer.writeln(
          '  - driver_access_token: ${driverToken?.substring(0, 30) ?? 'NULL'}...');
      debugBuffer.writeln(
          '  - auth_token: ${authToken?.substring(0, 30) ?? 'NULL'}...');
    } catch (e) {
      debugBuffer.writeln('  - Error reading SharedPreferences: $e');
    }
    debugBuffer.writeln('');

    // Check AuthService state
    debugBuffer.writeln('📱 AuthService Status:');
    debugBuffer
        .writeln('  - Is Authenticated: ${_authService.isAuthenticated}');
    debugBuffer.writeln(
        '  - Current Token: ${_authService.currentToken?.substring(0, 50) ?? 'NULL'}...');
    debugBuffer
        .writeln('  - Current Phone: ${_authService.currentPhone ?? 'NULL'}');
    debugBuffer.writeln(
        '  - Current User ID: ${_authService.currentUserId ?? 'NULL'}');
    debugBuffer.writeln('');

    // Check ApiService state
    debugBuffer.writeln('🔧 ApiService Status:');
    debugBuffer.writeln(
        '  - Token: ${_apiService.token?.substring(0, 50) ?? 'NULL'}...');
    debugBuffer.writeln('  - Token Length: ${_apiService.token?.length ?? 0}');
    debugBuffer.writeln(
        '  - Token starts with eyJ: ${_apiService.token?.startsWith('eyJ') ?? false}');
    debugBuffer.writeln('');

    // Check headers manually
    debugBuffer.writeln('🔧 Headers Debug:');
    try {
      // Call debugTokenAndHeaders and capture console output
      _apiService.debugTokenAndHeaders();
      debugBuffer.writeln('  - Headers debug called (check console)');
    } catch (e) {
      debugBuffer.writeln('  - Headers debug error: $e');
    }
    debugBuffer.writeln('');

    // Check SharedPreferences directly
    debugBuffer.writeln('💾 SharedPreferences Check:');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('driver_access_token');
      final savedPhone = prefs.getString('driver_phone_number');
      debugBuffer.writeln(
          '  - Saved Token: ${savedToken?.substring(0, 50) ?? 'NULL'}...');
      debugBuffer.writeln('  - Saved Phone: ${savedPhone ?? 'NULL'}');
      debugBuffer.writeln('  - Token Length: ${savedToken?.length ?? 0}');
      debugBuffer.writeln(
          '  - Token Type: ${savedToken != null && savedToken.startsWith('eyJ') ? 'JWT' : 'Unknown'}');
    } catch (e) {
      debugBuffer.writeln('  - SharedPreferences error: $e');
    }
    debugBuffer.writeln('');

    // Test token directly
    if (_authService.isAuthenticated) {
      debugBuffer.writeln('✅ Token found, testing API call...');
      try {
        final response =
            await _apiService.updateDriverLocation(10.762622, 106.660172);
        debugBuffer.writeln('📡 API Test Result:');
        debugBuffer.writeln('  - Success: ${response.success}');
        debugBuffer.writeln('  - Message: ${response.message ?? 'None'}');
        debugBuffer.writeln('  - Data: ${response.data}');

        if (!response.success && response.message?.contains('401') == true) {
          debugBuffer.writeln('');
          debugBuffer.writeln('❌ 401 ERROR DETECTED - TOKEN ISSUES:');
          debugBuffer.writeln('  - Token might be expired');
          debugBuffer.writeln('  - Token might not be sent in headers');
          debugBuffer.writeln('  - Profile might not be verified');
        }
      } catch (e) {
        debugBuffer.writeln('❌ API Test Error: $e');
      }
    } else {
      debugBuffer.writeln('❌ No token found - need to login first!');
    }

    setState(() {
      _debugInfo = debugBuffer.toString();
    });
  }

  Future<void> _testLogin() async {
    final debugBuffer = StringBuffer(_debugInfo);
    debugBuffer.writeln('\n🚀 Testing login with hardcoded credentials...');

    try {
      // Test với credentials từ Postman screenshot
      final response =
          await _authService.loginDriverWithPassword('+84867891733', '123456');

      debugBuffer.writeln('📊 Login Result:');
      debugBuffer.writeln('  - Success: ${response.success}');
      debugBuffer.writeln('  - Message: ${response.message ?? 'None'}');
      debugBuffer.writeln(
          '  - Token: ${response.data?.accessToken.substring(0, 20) ?? 'NULL'}...');

      if (response.success) {
        // Test API call after login
        final locationResponse =
            await _apiService.updateDriverLocation(10.762622, 106.660172);
        debugBuffer.writeln('\n📡 Location Update after login:');
        debugBuffer.writeln('  - Success: ${locationResponse.success}');
        debugBuffer
            .writeln('  - Message: ${locationResponse.message ?? 'None'}');
      }
    } catch (e) {
      debugBuffer.writeln('❌ Login Test Error: $e');
    }

    setState(() {
      _debugInfo = debugBuffer.toString();
    });
  }

  Future<void> _testLoginWithCredentials() async {
    final debugBuffer = StringBuffer(_debugInfo);
    debugBuffer.writeln('\n🚀 Testing manual token setup...');

    // Get the token from latest Postman login (from screenshot)
    final workingToken =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiZTc1NGJhOTgxN2E5ODUzNTYwMzQ1ODMyODkzYWRlNWY3YThlNDI4NmQwODhmNzAzZGVhZjMyMTc4OWRkZDgzNTNhOTMzMzlmNjE0MzEzZmQiLCJpYXQiOjE3MjAzMzYzNDEsIm5iZiI6MTcyMDMzNjM0MSwiZXhwIjoxNzUxODcyMzQxLCJzdWIiOiIxIiwic2NvcGVzIjpbXX0.FjbJDR2Yqj4PElNNyTAQ8LJe8YNIJqlXqJPRkzVrhTAP6ZOXM9hxZE8SjOpWvZ4_9I5YnMr6FQJqiGBE5GtGcWOBHR3JmEL8WVzqGJFOtREDtX_NHPMGiV8mN_pHQ2Mn1Zn-SgV0fShJ7oP2VJtqXAa1o7kOe2eUi4_oG0bF9xZLMX6VGZR2qJa_tvwa6RlK28dZRaA7hzjXV8gXK_7xIpPoIqCEUN36kB7Crl1Xi3nt9rkLD7s4df_IfWbhFU5v1HjCc5SD1m7TiVvmBsJjgkZy9xh6Xm0IpGoTp6-h67TDMo'; // From latest login screenshot

    debugBuffer.writeln('🔧 Setting hardcoded token that worked in Postman...');
    debugBuffer.writeln('Token: $workingToken');

    // Set token directly in ApiService
    _apiService.setToken(workingToken);

    // Test API call with the working token
    try {
      final response =
          await _apiService.updateDriverLocation(10.762622, 106.660172);
      debugBuffer.writeln('\n📡 API Test with Postman Token:');
      debugBuffer.writeln('  - Success: ${response.success}');
      debugBuffer.writeln('  - Message: ${response.message ?? 'None'}');
      debugBuffer.writeln('  - Data: ${response.data}');

      if (response.success) {
        debugBuffer.writeln('✅ SUCCESS! Postman token works in Flutter!');
        debugBuffer.writeln('💡 Problem: App token != Postman token');
      } else {
        debugBuffer.writeln('❌ Even Postman token fails in Flutter');
        debugBuffer.writeln('💡 Problem: Headers or request format issue');
      }
    } catch (e) {
      debugBuffer.writeln('❌ Test with Postman token failed: $e');
    }

    setState(() {
      _debugInfo = debugBuffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDebug,
                    child: const Text('Refresh Debug'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Test Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLoginWithCredentials,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Test Postman Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _apiService.debugTokenAndHeaders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Headers logged to console'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Debug Headers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
