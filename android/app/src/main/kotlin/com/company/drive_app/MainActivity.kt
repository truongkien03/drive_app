package com.company.drive_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "proximity_service" // Phải giống với notificationChannelId trong Dart
            val channelName = "Dịch vụ kiểm tra khoảng cách"
            val importance = NotificationManager.IMPORTANCE_LOW

            val channel = NotificationChannel(channelId, channelName, importance)
            channel.description = "Channel cho service kiểm tra vị trí"

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
