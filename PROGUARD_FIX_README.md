# Flutter Local Notifications ProGuard Fix

## Problem
Flutter Local Notifications was crashing in release builds due to missing TypeToken generic type information. R8/ProGuard was stripping the generic type information required by Gson for serialization.

## Solution Implemented

### 1. Created ProGuard Rules File
**File:** `android/app/proguard-rules.pro`

Key rules added:
- Keep TypeToken generic signatures
- Protect flutter_local_notifications classes
- Preserve notification framework classes
- Keep Gson serialization attributes

### 2. Updated Build Configuration
**File:** `android/app/build.gradle.kts`

Changes:
- Enabled `isMinifyEnabled = true` for release builds
- Added ProGuard rules file reference
- Configured optimization settings

### 3. Testing
Run release build to test:
```bash
flutter clean
flutter build apk --release
```

## Files Modified

1. **`android/app/proguard-rules.pro`** (created)
   - TypeToken protection rules
   - Flutter Local Notifications specific rules
   - General Android notification rules

2. **`android/app/build.gradle.kts`** (modified)
   - Added ProGuard configuration
   - Enabled code shrinking for release builds

## Expected Result
- Release builds will no longer crash due to missing TypeToken information
- Flutter Local Notifications will work correctly in production
- App size will be optimized through ProGuard code shrinking

## Dependencies Protected
- flutter_local_notifications: ^17.1.2
- permission_handler (for notification permissions)
- Firebase/Firestore classes
- Gson TypeToken and reflection classes
