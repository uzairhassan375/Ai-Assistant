# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep generic signature for TypeToken (required by Gson)
-keepattributes Signature

# Keep generic types for Flutter Local Notifications
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter Local Notifications classes
-keep class com.dexterous.** { *; }
-keep class dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep notification-related classes
-keep class * extends android.app.Notification$* { *; }
-keep class * extends androidx.core.app.NotificationCompat$* { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }

# Keep timezone classes (used by flutter_local_notifications)
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**

# Gson specific rules
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep TypeToken and related generic information
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Preserve generic signatures for Gson TypeToken
-keepattributes Signature,RuntimeVisibleAnnotations,AnnotationDefault

# Keep all enum classes (often used in notifications)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep serialization annotations
-keepattributes *Annotation*

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Deferred components (Play Store functionality)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Permission handler (used by notifications)
-keep class com.baseflow.permissionhandler.** { *; }

# Firebase related (since you're using Firebase)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Play Core (required for Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes that might be used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
