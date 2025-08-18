import 'package:flutter/material.dart';
import 'package:aiassistant1/services/task_notification_service.dart';
import 'package:aiassistant1/models/task.dart';

/// Widget to test the enhanced notification system
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final TaskNotificationService _notificationService = TaskNotificationService();
  String _testStatus = 'Ready to test notifications';
  bool _isLoading = false;

  Future<void> _testImmediateNotification() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Sending immediate notification...';
    });

    try {
      await _notificationService.showImmediateNotification(
        title: '🧪 Test Immediate Notification',
        body: 'This is a test immediate notification. Time: ${DateTime.now()}',
        payload: 'test_immediate',
      );
      
      setState(() {
        _testStatus = '✅ Immediate notification sent successfully!';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ Error sending immediate notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testScheduledNotification() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Scheduling test notifications...';
    });

    try {
      await _notificationService.testNotificationScheduling();
      
      setState(() {
        _testStatus = '✅ Test notifications scheduled! Check in 10-19 seconds.\n\nPut the app in background to test reliability.';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ Error scheduling test notifications: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTaskNotification() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Scheduling task notification...';
    });

    try {
      // Create a test task due in 15 seconds
      final testTask = Task(
        id: 'test_task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Task Notification',
        description: 'This is a test task to verify notification scheduling works correctly.',
        dueDate: DateTime.now().add(const Duration(seconds: 15)),
        priority: TaskPriority.high,
        category: 'test',
        isReminder: true,
        isCompleted: false,
        isArchived: false,
        userId: 'test_user',
      );

      await _notificationService.scheduleTaskNotification(testTask);
      
      setState(() {
        _testStatus = '✅ Task notification scheduled for 15 seconds!\n\nPut app in background to test. You should see multiple notifications with different strategies.';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ Error scheduling task notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Checking system permissions...';
    });

    try {
      final status = await _notificationService.getSystemNotificationStatus();
      
      setState(() {
        _testStatus = 'System Status:\n${status.entries.map((e) => '${e.key}: ${e.value}').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ Error checking permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPendingNotifications() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Getting pending notifications...';
    });

    try {
      final count = await _notificationService.getPendingNotificationCount();
      final pending = await _notificationService.getPendingNotifications();
      
      setState(() {
        _testStatus = 'Pending Notifications: $count\n\n${pending.map((n) => 'ID: ${n.id}, Title: ${n.title}').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ Error getting pending notifications: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification System Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enhanced Notification System Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testImmediateNotification,
              child: const Text('Test Immediate Notification'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testScheduledNotification,
              child: const Text('Test Multi-Strategy Scheduling (10s)'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testTaskNotification,
              child: const Text('Test Task Notification (15s)'),
            ),
            const SizedBox(height: 16),
            
            const Divider(),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _checkPermissions,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Check System Status'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _getPendingNotifications,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Check Pending Notifications'),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              
            const Spacer(),
            
            const Card(
              color: Colors.lightBlue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Test immediate notification first\n'
                      '2. Schedule test notifications\n'
                      '3. Put app in background immediately\n'
                      '4. Wait for notifications to appear\n'
                      '5. Check if multiple notifications arrive\n'
                      '6. Verify notifications work even when app is killed',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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
