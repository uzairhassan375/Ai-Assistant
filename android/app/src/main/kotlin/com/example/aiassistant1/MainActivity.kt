package com.example.aiassistant1

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.example.aiassistant1/notifications"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for custom notification handling
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearCorruptedNotifications" -> {
                        try {
                            NotificationStorageHelper.clearScheduledNotifications(this)
                            result.success("Cleared corrupted notifications")
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to clear notifications: ${e.message}", null)
                        }
                    }
                    "getScheduledNotificationCount" -> {
                        try {
                            val count = NotificationStorageHelper.loadScheduledNotifications(this).size
                            result.success(count)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get notification count: ${e.message}", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize notification system
        try {
            // Clear any corrupted notification data on app start
            // This helps prevent the TypeToken issues
            val notifications = NotificationStorageHelper.loadScheduledNotifications(this)
            // If loading succeeds, the data is valid
        } catch (e: Exception) {
            // If loading fails due to TypeToken issues, clear the data
            NotificationStorageHelper.clearScheduledNotifications(this)
        }
    }
}
