# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter Local Notifications - Fix Gson TypeToken issues
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep generic signature of TypeToken and related classes
-keepclassmembers,allowshrinking,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Flutter Local Notifications specific
-keep class com.dexterous.** { *; }
-keep class dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class dexterous.flutterlocalnotifications.** {
    <fields>;
    <methods>;
}

# Keep notification model classes
-keep class dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class dexterous.flutterlocalnotifications.models.** {
    <fields>;
    <methods>;
}

# Keep scheduled notification models
-keep class dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver$* { *; }

# Generic signature preservation for TypeToken
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Engine
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Google Play Core (Fix for missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent obfuscation of classes with generic signatures
-keepattributes Signature
-keep class * extends java.lang.reflect.ParameterizedType { *; }

# Keep our custom notification helper
-keep class com.example.aiassistant1.NotificationStorageHelper { *; }
-keep class com.example.aiassistant1.ScheduledNotificationModel { *; }

# Permissions handler
-keep class com.baseflow.permissionhandler.** { *; }

# Speech to text
-keep class com.csdcorp.speech_to_text.** { *; }

# Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }