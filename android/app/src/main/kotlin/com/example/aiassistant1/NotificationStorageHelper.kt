package com.example.aiassistant1

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type

/**
 * Custom notification storage helper that properly handles Gson TypeToken
 * to fix the "TypeToken must be created with a type argument" error
 */
class NotificationStorageHelper {
    companion object {
        private const val SHARED_PREFERENCES_KEY = "flutter_local_notifications_plugin"
        private const val SCHEDULED_NOTIFICATIONS_KEY = "scheduled_notifications"
        
        private val gson = Gson()
        
        // Properly defined TypeToken with generic type argument
        private val notificationListType: Type = object : TypeToken<List<ScheduledNotificationModel>>() {}.type
        
        /**
         * Save scheduled notifications with proper generic type handling
         */
        fun saveScheduledNotifications(context: Context, notifications: List<ScheduledNotificationModel>) {
            val sharedPreferences = getSharedPreferences(context)
            val json = gson.toJson(notifications, notificationListType)
            sharedPreferences.edit()
                .putString(SCHEDULED_NOTIFICATIONS_KEY, json)
                .apply()
        }
        
        /**
         * Load scheduled notifications with proper generic type handling
         */
        fun loadScheduledNotifications(context: Context): List<ScheduledNotificationModel> {
            val sharedPreferences = getSharedPreferences(context)
            val json = sharedPreferences.getString(SCHEDULED_NOTIFICATIONS_KEY, null)
                ?: return emptyList()
            
            return try {
                gson.fromJson(json, notificationListType) ?: emptyList()
            } catch (e: Exception) {
                // If deserialization fails, return empty list and clear corrupted data
                clearScheduledNotifications(context)
                emptyList()
            }
        }
        
        /**
         * Clear all scheduled notifications
         */
        fun clearScheduledNotifications(context: Context) {
            val sharedPreferences = getSharedPreferences(context)
            sharedPreferences.edit()
                .remove(SCHEDULED_NOTIFICATIONS_KEY)
                .apply()
        }
        
        /**
         * Remove a specific scheduled notification
         */
        fun removeScheduledNotification(context: Context, notificationId: Int) {
            val notifications = loadScheduledNotifications(context).toMutableList()
            notifications.removeAll { it.id == notificationId }
            saveScheduledNotifications(context, notifications)
        }
        
        /**
         * Add a scheduled notification
         */
        fun addScheduledNotification(context: Context, notification: ScheduledNotificationModel) {
            val notifications = loadScheduledNotifications(context).toMutableList()
            // Remove existing notification with same ID if present
            notifications.removeAll { it.id == notification.id }
            notifications.add(notification)
            saveScheduledNotifications(context, notifications)
        }
        
        private fun getSharedPreferences(context: Context): SharedPreferences {
            return context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
        }
    }
}

/**
 * Data model for scheduled notifications
 * This mirrors the structure expected by flutter_local_notifications
 */
data class ScheduledNotificationModel(
    val id: Int,
    val title: String?,
    val body: String?,
    val payload: String?,
    val scheduledDateTime: String,
    val timeZoneName: String?,
    val matchDateTimeComponents: String?,
    val uiLocalNotificationDateInterpretation: String?,
    val platformChannelSpecifics: Map<String, Any>?
)
