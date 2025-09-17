# 🔔 Notification Sounds Guide

## 🔊 Current Notification Sounds

Your app now uses different sounds for different notification types:

### **📋 Task Reminders (Due Time)**
- **Sound**: `alarm_sound` (Alarm category)
- **Priority**: Maximum
- **Vibration**: Strong
- **Purpose**: Wake you up for important tasks

### **⏰ Task Due Soon (5 minutes before)**
- **Sound**: `notification_sound` (Reminder category)
- **Priority**: High
- **Vibration**: Normal
- **Purpose**: Gentle reminder

### **🚨 Overdue Tasks (5 minutes after)**
- **Sound**: `alarm_sound` (Alarm category)
- **Priority**: Maximum
- **Vibration**: Strong
- **Purpose**: Urgent alert

## 🎵 How to Add Custom Sounds

### **For Android:**

1. **Add sound files** to `android/app/src/main/res/raw/`:
   - `notification_sound.mp3` (for gentle reminders)
   - `alarm_sound.mp3` (for urgent alerts)

2. **Supported formats**: MP3, WAV, OGG

3. **File size**: Keep under 1MB for best performance

### **For iOS:**

1. **Add sound files** to `ios/Runner/`:
   - `notification_sound.aiff` (for gentle reminders)
   - `alarm_sound.aiff` (for urgent alerts)

2. **Supported formats**: AIFF, WAV, CAF

3. **Duration**: Keep under 30 seconds

## 🎧 Default Sounds (If No Custom Sounds)

If you don't add custom sound files, the app will use:
- **Android**: System default notification/alarm sounds
- **iOS**: System default notification/alarm sounds

## 🔧 Testing Sounds

Use the test function in your app:
```dart
final notificationService = SimpleNotificationService();
await notificationService.showTestNotificationIn10Seconds(context);
```

## 📱 Sound Categories

- **Alarm Category**: Bypasses Do Not Disturb mode
- **Reminder Category**: Respects Do Not Disturb settings
- **Time Sensitive**: iOS will show even in Focus mode

## 🎵 Recommended Sound Files

### **For Gentle Reminders:**
- Soft chime
- Gentle bell
- Subtle notification tone

### **For Urgent Alerts:**
- Alarm clock sound
- Urgent beep
- Attention-grabbing tone

## 📝 Example Sound Files

You can download free notification sounds from:
- [Freesound.org](https://freesound.org)
- [Zapsplat.com](https://zapsplat.com)
- [Adobe Audition](https://audition.adobe.com)

Make sure to use royalty-free sounds for your app!
