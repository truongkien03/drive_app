import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    // Đợi một chút để NotificationService khởi tạo
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _fcmToken = NotificationService.currentToken;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Token',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Dimension.font_size16,
                      ),
                    ),
                    SizedBox(height: Dimension.height8),
                    if (_isLoading)
                      CircularProgressIndicator()
                    else if (_fcmToken != null)
                      Container(
                        padding: EdgeInsets.all(Dimension.width12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(Dimension.radius8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Token:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: Dimension.height4),
                            Text(
                              _fcmToken!,
                              style: TextStyle(
                                fontSize: Dimension.font_size12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: Dimension.height8),
                            Row(
                              children: [
                                Icon(Icons.copy, size: Dimension.icon16),
                                SizedBox(width: Dimension.width4),
                                Text(
                                  'Tap to copy',
                                  style: TextStyle(
                                    fontSize: Dimension.font_size12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'FCM Token not available',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Dimension.height16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Dimension.font_size16,
                      ),
                    ),
                    SizedBox(height: Dimension.height16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.testLocalNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🔔 Test notification sent!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.notifications),
                      label: Text('Send Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: Dimension.height12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _loadFCMToken();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🔄 FCM Token refreshed!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh FCM Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Dimension.height16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Dimension.font_size16,
                      ),
                    ),
                    SizedBox(height: Dimension.height12),
                    Row(
                      children: [
                        Icon(
                          NotificationService.isInitialized
                              ? Icons.check_circle
                              : Icons.error,
                          color: NotificationService.isInitialized
                              ? Colors.green
                              : Colors.red,
                          size: Dimension.icon20,
                        ),
                        SizedBox(width: Dimension.width8),
                        Text(
                          NotificationService.isInitialized
                              ? 'Notification Service: Initialized'
                              : 'Notification Service: Not Initialized',
                          style: TextStyle(
                            color: NotificationService.isInitialized
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 