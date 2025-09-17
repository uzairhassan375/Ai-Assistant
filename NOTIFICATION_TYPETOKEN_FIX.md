# Flutter Local Notifications TypeToken Fix

## Problem Description

The `flutter_local_notifications` plugin can throw a `PlatformException` with the error message:
```
TypeToken must be created with a type argument
```

This occurs when the Android native code tries to serialize/deserialize notification data using Gson without proper generic type arguments, especially when ProGuard/R8 obfuscation is enabled.

## Root Cause

The issue stems from:
1. **Raw TypeToken usage**: The plugin's Android code uses raw `TypeToken` without generic type arguments
2. **ProGuard/R8 obfuscation**: Generic signatures are removed during obfuscation
3. **Corrupted data**: Previously stored notification data may become incompatible

## Solution Implementation

### 1. ProGuard Rules (`android/app/proguard-rules.pro`)

Added comprehensive ProGuard rules to:
- Preserve generic signatures (`-keepattributes Signature`)
- Keep Gson classes and TypeToken with proper generics
- Protect flutter_local_notifications plugin classes
- Prevent obfuscation of notification model classes

Key rules:
```proguard
-keepattributes Signature
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class dexterous.flutterlocalnotifications.** { *; }
```

### 2. Custom Android Storage Helper

Created `NotificationStorageHelper.kt` that:
- Uses properly typed `TypeToken<List<ScheduledNotificationModel>>()`
- Handles serialization/deserialization errors gracefully
- Provides methods to clear corrupted data
- Implements proper generic type handling

### 3. Enhanced MainActivity

Updated `MainActivity.kt` to:
- Initialize notification system safely
- Provide method channel for clearing corrupted data
- Handle TypeToken errors during app startup

### 4. Dart-side Error Handling

Enhanced `NotificationService`:
- Catches TypeToken exceptions
- Automatically clears corrupted data and retries
- Provides debugging methods
- Graceful fallback for initialization failures

### 5. Testing and Debugging Tools

Added comprehensive testing via `ReminderWidget`:
- Test immediate notifications
- Test scheduled notifications
- Check notification count
- Clear all notifications
- Monitor for TypeToken errors

## Usage

### For Users
The fix is transparent - notifications will work normally. If TypeToken errors occur:
1. The app automatically clears corrupted data
2. Retries the operation
3. Shows helpful error messages

### For Developers
Use debugging methods:
```dart
// Check notification count
final count = await NotificationService().getScheduledNotificationCount();

// Clear all notifications if issues persist
await NotificationService().clearAllNotifications();

// Test notifications
await NotificationService().scheduleTestNotification(
  title: 'Test',
  body: 'Test notification'
);
```

## Build Configuration

Ensure ProGuard is enabled in `android/app/build.gradle.kts`:
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

## Testing the Fix

1. **Build release APK**: `flutter build apk --release`
2. **Test notifications**: Use the reminder widget test buttons
3. **Monitor logs**: Check for TypeToken errors in debug console
4. **Verify persistence**: Schedule notifications and restart the app

## Additional Notes

- The fix preserves all existing notification functionality
- Performance impact is minimal
- Compatible with all Android versions supported by the plugin
- Works with both debug and release builds
- Handles edge cases like app crashes during notification scheduling

## Troubleshooting

If TypeToken errors persist:
1. Clear app data and try again
2. Use the "Clear All" button in the reminder widget
3. Check ProGuard rules are applied correctly
4. Verify the custom storage helper is being used

The implementation ensures robust notification handling while maintaining compatibility with ProGuard/R8 optimization.
