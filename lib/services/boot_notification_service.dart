import 'package:aiassistant1/services/task_notification_integration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle notification rescheduling after device boot or app updates
class BootNotificationService {
  static final BootNotificationService _instance = BootNotificationService._internal();
  factory BootNotificationService() => _instance;
  BootNotificationService._internal();

  final TaskNotificationIntegration _notificationIntegration = TaskNotificationIntegration();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _hasHandledBoot = false;

  /// Handle boot completed event
  Future<void> handleBootCompleted() async {
    if (kIsWeb || _hasHandledBoot) return;
    
    try {
      print('BootNotificationService: Handling boot completed event...');
      
      // Wait for Firebase to initialize
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('BootNotificationService: No authenticated user, skipping notification rescheduling');
        return;
      }
      
      // Reinitialize notification integration
      await _notificationIntegration.reinitialize();
      
      _hasHandledBoot = true;
      print('BootNotificationService: Boot handling completed successfully');
      
    } catch (e) {
      print('BootNotificationService: Error handling boot completed: $e');
    }
  }

  /// Handle app launched after update
  Future<void> handleAppUpdate() async {
    if (kIsWeb) return;
    
    try {
      print('BootNotificationService: Handling app update...');
      
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('BootNotificationService: No authenticated user, skipping notification rescheduling');
        return;
      }
      
      // Reinitialize notification integration
      await _notificationIntegration.reinitialize();
      
      print('BootNotificationService: App update handling completed successfully');
      
    } catch (e) {
      print('BootNotificationService: Error handling app update: $e');
    }
  }

  /// Check if notifications need rescheduling on app launch
  Future<void> checkAndRescheduleOnLaunch() async {
    if (kIsWeb) return;
    
    try {
      // Get last app launch time from SharedPreferences
      // If it's been more than a few hours, reschedule notifications
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      print('BootNotificationService: Checking if rescheduling needed on launch...');
      
      // For now, always reinitialize to ensure reliability
      // In production, you might want to check timestamp to avoid unnecessary work
      await _notificationIntegration.reinitialize();
      
      print('BootNotificationService: Launch rescheduling completed');
      
    } catch (e) {
      print('BootNotificationService: Error checking/rescheduling on launch: $e');
    }
  }

  /// Reset boot handling flag (for testing)
  void resetBootHandling() {
    _hasHandledBoot = false;
  }
}
